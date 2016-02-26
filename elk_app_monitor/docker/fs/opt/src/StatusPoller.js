/**
 * Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
 * This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
 * and may not be copied, reproduced, modified, disclosed to others, published or used,
 * in whole or in part, without the express prior written permission of ARRIS.
 */

/**
 * This file defines the ELK status polling process
 */

/**
 * Import modules
 */
var appLogger = require('../utils/app_logger');
var http = require('http');
var xmlBuilder = require('xmlbuilder');

/**
 * Consts
 */
var POLL_PERIOD = 60 * 1000; // milliseconds
var ES_PORT = 9200; 

var ITEM_ID = "com.ccadllc.elk.cluster.health";
var ITEM_SUMMARY = "Cluster Health";
var ITEM_DETAIL_GREEN = "All shards are allocated.";
var ITEM_DETAIL_YELLOW = "Some indices are missing replica shards. The cluster is still operational but may have degraded performance or failover capabilities.";
var ITEM_DETAIL_RED = "Some indices are not operational due to missing primary shards.";
var ITEM_SEVERITY_INFORMATIONAL = "INFORMATIONAL";
var ITEM_SEVERITY_WARNING = "WARNING";
var ITEM_SEVERITY_ERROR = "ERROR";

var ES_STATUS_GREEN = "green";
var ES_STATUS_YELLOW = "yellow";
var ES_STATUS_RED = "red";

//parameters for HTTP request to Elasticsearch API
var optionsES =
{
  host: process.argv[3],
  path: '/_cluster/health',
  port: ES_PORT,
  method: 'GET'
};

var optionsAO =
{
  host: process.argv[3],
  path: '/app-observer/status_items',
  port: process.argv[4],
  method: 'PUT'
};

/**
 * Module class definition
 */
module.exports = function()
{
  appLogger.info("=======Status Poller Starts========");

  /**
   * Kick off status poll
   */
  this.startPoll = function()
  {
    setInterval(poll, POLL_PERIOD);
  }

  /**
   * Poll operation
   */
  poll = function()
  {
    appLogger.info("StatusPoller.poll.enter");

    //send HTTP request to Elasticsearch cluster health API, with callback function
    var request = http.request(optionsES,
      function(response)
      {
        var response_str = '';

        //continue to retrieve date until done
        response.on('data',
          function(chunk)
          {
            response_str += chunk;
          }
        );

        //the whole response has been recieved, process the result
        response.on('end',
          function ()
          {
            appLogger.info("Received Elasticsearch cluster health API response: %s", response_str);

            //parse the JSON result
            var json_response = JSON.parse(response_str);

            //get the status color coding
            var statusES = json_response.status;

            //send status report to AppObserver
            sendReport(statusES); 
          }
        );
      } //end HTTP request callback function def
    ); //end send HTTP request

    //request error handling
    request.on('error',
      function(e)
      {
        appLogger.error("Error when sending HTTP request to Elasticsearch cluster health API. Error: " + e.message +
                         ". No status report is generated for AppObserver");
      }
    );

    request.end();

    appLogger.info("StatusPoller.poll.exit");
  }

  /**
   * Send the XML status report to appobserver
   */
  sendReport = function(statusES)
  {
    appLogger.info("StatusPoller.sendReport.enter");

    //build the XML for status report
    var xml = xmlBuilder.create('statusItems', {headless: true});
    var scalarItems = xml.ele('scalarItems');
    if (statusES.toLowerCase() === ES_STATUS_GREEN.toLowerCase())
    {
      scalarItems.ele('scalarItem', {'id': ITEM_ID, 'summary': ITEM_SUMMARY,
                                     'detail': ITEM_DETAIL_GREEN, 'severity': ITEM_SEVERITY_INFORMATIONAL});
    }
    else if (statusES.toLowerCase() === ES_STATUS_YELLOW.toLowerCase())
    {
      scalarItems.ele('scalarItem', {'id': ITEM_ID, 'summary': ITEM_SUMMARY,
                                     'detail': ITEM_DETAIL_YELLOW, 'severity': ITEM_SEVERITY_WARNING});
    }
    else if (statusES.toLowerCase() === ES_STATUS_RED.toLowerCase())
    {
      scalarItems.ele('scalarItem', {'id': ITEM_ID, 'summary': ITEM_SUMMARY,
                                     'detail': ITEM_DETAIL_RED, 'severity': ITEM_SEVERITY_ERROR});
    }

    var compositeItems = xml.ele('compositeItems');
    xml.end();
    
    appLogger.info("Status report XML: " + xml);

    //send HTTP PUT request to appobserver 
    optionsAO.headers = {'Content-Type': 'application/xml; charset=utf-8',
                         'Content-Length': Buffer.byteLength(xml.toString())};

    var request = http.request(optionsAO,
      function(response)
      {
        var response_str = '';

        //continue to retrieve date until done
        response.on('data',
          function(chunk)
          {
            response_str += chunk;
          }
        );

        //the whole response has been recieved, process the result
        response.on('end',
          function ()
          {
            appLogger.info("Received AppObserver status report response.");
          }
        );
      } //end HTTP request callback function def
    ); //end send HTTP request 

    //request error handling
    request.on('error',
      function(e)
      {
        appLogger.error("Error when sending status report to AppObserver, Error: " + e.message);
      }
    ); 

    request.write(xml.toString()); 
    request.end();

    appLogger.info("StatusPoller.sendReport.exit"); 
  }   
}
