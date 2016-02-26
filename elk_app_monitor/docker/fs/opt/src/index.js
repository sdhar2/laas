/**
 * Copyright 2015 ARRIS Enterprises, Inc. All rights reserved.
 * This program is confidential and proprietary to ARRIS Enterprises, Inc. (ARRIS),
 * and may not be copied, reproduced, modified, disclosed to others, published or used,
 * in whole or in part, without the express prior written permission of ARRIS.
 */

/**
 * Main body of Express to handle routes
 */

var express = require('express');
var router = express.Router();
var appLogger = require('../utils/app_logger');
var http = require('http');
var StatusPoller = require("./StatusPoller");

var statusPoller = new StatusPoller();
statusPoller.startPoll();

//define parameters for HTTP request to HAProxy status API
var options =
{
  host: process.argv[3],
  path: '/_nodes/_local/stats/indices,fs',
  port: '9200',
  method: 'GET'
};

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});

/* app-observer performance poll REST APIs */
/* named queries */
router.get('/observer-app/named_query/Indexing',
  function(req, res, next)
  {
    appLogger.info("Performance monitor received named_query request: Indexing. Request details: source IP=%s, web server hostname=%s, protocol=%s", req.ip, req.hostname, req.protocol);

    //send HTTP request to Elasticsearch node stats API, with callback function
    var request = http.request(options, 
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
            appLogger.info("Received Elasticsearch node stats API response: %s", response_str);

            //parsing the JSON result
            var json_response = JSON.parse(response_str);

            //figure out the value of the dynamic node key
            var nodesKeyES = Object.keys(json_response.nodes)[0];
            var indexingES = json_response.nodes[nodesKeyES].indices.indexing.index_time_in_millis;

            //build the JSON response
            var monitor_json_response = {};
            var indexingArray = [];
            var indexing = {name: "IndexingTime", value: indexingES};
            indexingArray.push(indexing);
            monitor_json_response.Indexing = indexingArray;
             
            appLogger.info("Sending JSON response to app-observer: %s", JSON.stringify(monitor_json_response)); 

            res.set('Content-Type', 'application/json');
            res.send(JSON.stringify(monitor_json_response));
          }
        );
      } //end HTTP request callback function def
    ); //end send HTTP request

    //request error handling
    request.on('error', 
      function(e) 
      {
        appLogger.error("Error when sending HTTP request to Elasticsearch node stats API. " + e.message);
        res.status(500).send('Server Internal Error - Elasticsearch node stats API is down');
      }
    );

    request.end();
  } //end router middleware function 
); 

router.get('/observer-app/named_query/Search',
  function(req, res, next)
  {
    appLogger.info("Performance monitor received named_query request: Search. Request details: source IP=%s, web server hostname=%s, protocol=%s", req.ip, req.hostname, req.protocol);

    //send HTTP request to Elasticsearch node stats API, with callback function
    var request = http.request(options, 
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
            appLogger.info("Received Elasticsearch node stats API response: %s", response_str);

            //parsing the JSON result
            var json_response = JSON.parse(response_str);

            //figure out the value of the dynamic node key
            var nodesKeyES = Object.keys(json_response.nodes)[0];
            var searchES = json_response.nodes[nodesKeyES].indices.search.query_time_in_millis;

            //build the JSON response
            var monitor_json_response = {};
            var searchArray = [];
            var search = {name: "SearchTime", value: searchES};
            searchArray.push(search);
            monitor_json_response.Search = searchArray;
             
            appLogger.info("Sending JSON response to app-observer: %s", JSON.stringify(monitor_json_response)); 

            res.set('Content-Type', 'application/json');
            res.send(JSON.stringify(monitor_json_response));
          }
        );
      } //end HTTP request callback function def
    ); //end send HTTP request

    //request error handling
    request.on('error', 
      function(e) 
      {
        appLogger.error("Error when sending HTTP request to Elasticsearch node stats API. " + e.message);
        res.status(500).send('Server Internal Error - Elasticsearch node stats API is down');
      }
    );

    request.end();
  } //end router middleware function 
); 

router.get('/observer-app/named_query/FreeDiskSpace',
  function(req, res, next)
  {
    appLogger.info("Performance monitor received named_query request: Search. Request details: source IP=%s, web server hostname=%s, protocol=%s", req.ip, req.hostname, req.protocol);

    //send HTTP request to Elasticsearch node stats API, with callback function
    var request = http.request(options, 
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
            appLogger.info("Received Elasticsearch node stats API response: %s", response_str);

            //parsing the JSON result
            var json_response = JSON.parse(response_str);

            //figure out the value of the dynamic node key
            var nodesKeyES = Object.keys(json_response.nodes)[0];
            var freeDiskSpaceES = json_response.nodes[nodesKeyES].fs.total.free_in_bytes;

            //build the JSON response
            var monitor_json_response = {};
            var freeDiskSpaceArray = [];
            var freeDiskSpace = {name: "FreeDiskSpace", value: freeDiskSpaceES};
            freeDiskSpaceArray.push(freeDiskSpace);
            monitor_json_response.FreeDiskSpace = freeDiskSpaceArray;
             
            appLogger.info("Sending JSON response to app-observer: %s", JSON.stringify(monitor_json_response)); 

            res.set('Content-Type', 'application/json');
            res.send(JSON.stringify(monitor_json_response));
          }
        );
      } //end HTTP request callback function def
    ); //end send HTTP request

    //request error handling
    request.on('error', 
      function(e) 
      {
        appLogger.error("Error when sending HTTP request to Elasticsearch node stats API. " + e.message);
        res.status(500).send('Server Internal Error - Elasticsearch node stats API is down');
      }
    );

    request.end();
  } //end router middleware function 
);

module.exports = router;
