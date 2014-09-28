- [Dropwizard Metrics Stats For Logstash](#dropwizard-metrics-stats-for-logstash)
    - [Configuration](#configuration)
	    - [Extracting all stats as searchable fields](#extracting-all-stats-as-searchable-fields)
	    - [Polling Frequency](#polling-frequency)
	    - [Specifying the metrics admin endpoint](#specifying-the-metrics-admin-endpoint)
	    - [Specifying the key/value separator](#specifying-the-key-and-value-separator)
	    - [Specifying the delimeter between the different stats](#specifying-the-delimeter-between-the-different-stats)
	    - [Retry on Connection Failure](#retry-on-connection-failure)
    - [Installation](#installation)
    - [Example kibana tracking](#example-kibana-tracking)
    - [License](#license)        	    
	    

# Dropwizard Metrics Stats For Logstash

An Input for obtaining dropwizard metrics from the admin endpoint of your application
(http://dropwizard.io/getting-started.html#running-your-application) for logstash.
The input connects to a the http admin metric endpoint periodically, and the yammer metrics json is
turned either into key/value event pairs, or just assembled into key value pairs
in a message event, for parsing via a custom logstash filter:

By default the plugin only obtains a subsection of the metrics that are output, those of the jvm gc statistics, 
as follows:


    {  
        "message":"|gaugesjvmgcpsmarksweepcountvalue=1|gaugesjvmgcpsmarksweeptimevalue=65|gaugesjvmgcpsscavengecountvalue=4|gaugesjvmgcpsscavengetimevalue=88|gaugesjvmmemoryheapcommittedvalue=503316480|gaugesjvmmemoryheapinitvalue=536870912|gaugesjvmmemoryheapmaxvalue=503316480|gaugesjvmmemoryheapusagevalue=0.28561333020528157|gaugesjvmmemoryheapusedvalue=143753896|gaugesjvmmemorynonheapcommittedvalue=54165504|gaugesjvmmemorynonheapinitvalue=2555904|gaugesjvmmemorynonheapmaxvalue=-1|gaugesjvmmemorynonheapusagevalue=-53151384.0|gaugesjvmmemorynonheapusedvalue=53151384|gaugesjvmmemorypoolscodecacheusagevalue=0.06961390177408854|gaugesjvmmemorypoolscompressedclassspaceusagevalue=0.003796711564064026|gaugesjvmmemorypoolsmetaspaceusagevalue=0.9771751430904363|gaugesjvmmemorypoolspsedenspaceusagevalue=0.6016255219777426|gaugesjvmmemorypoolspsoldgenusagevalue=0.06402626633644104|gaugesjvmmemorypoolspssurvivorspaceusagevalue=0.16223669052124023|gaugesjvmmemorytotalcommittedvalue=557481984|gaugesjvmmemorytotalinitvalue=539426816|gaugesjvmmemorytotalmaxvalue=503316479|gaugesjvmmemorytotalusedvalue=196905280|",
        "@version":"1",
        "@timestamp":"2014-09-28T16:43:26.724Z",
        "gaugesjvmgcpsmarksweepcountvalue":1.0,
        "gaugesjvmgcpsmarksweeptimevalue":65.0,
        "gaugesjvmgcpsscavengecountvalue":4.0,
        "gaugesjvmgcpsscavengetimevalue":88.0,
        "gaugesjvmmemoryheapcommittedvalue":503316480.0,
        "gaugesjvmmemoryheapinitvalue":536870912.0,
        "gaugesjvmmemoryheapmaxvalue":503316480.0,
        "gaugesjvmmemoryheapusagevalue":0.28561333020528157,
        "gaugesjvmmemoryheapusedvalue":143753896.0,
        "gaugesjvmmemorynonheapcommittedvalue":54165504.0,
        "gaugesjvmmemorynonheapinitvalue":2555904.0,
        "gaugesjvmmemorynonheapmaxvalue":-1.0,
        "gaugesjvmmemorynonheapusagevalue":-53151384.0,
        "gaugesjvmmemorynonheapusedvalue":53151384.0,
        "gaugesjvmmemorypoolscodecacheusagevalue":0.06961390177408854,
        "gaugesjvmmemorypoolscompressedclassspaceusagevalue":0.003796711564064026,
        "gaugesjvmmemorypoolsmetaspaceusagevalue":0.9771751430904363,
        "gaugesjvmmemorypoolspsedenspaceusagevalue":0.6016255219777426,
        "gaugesjvmmemorypoolspsoldgenusagevalue":0.06402626633644104,
        "gaugesjvmmemorypoolspssurvivorspaceusagevalue":0.16223669052124023,
        "gaugesjvmmemorytotalcommittedvalue":557481984.0,
        "gaugesjvmmemorytotalinitvalue":539426816.0,
        "gaugesjvmmemorytotalmaxvalue":503316479.0,
        "gaugesjvmmemorytotalusedvalue":196905280.0,
        "host":"localhost.localdomain",
        "type":"metricstats",
        "metricshost":"localhost",
        "metricsport":8081
    }

## Configuration

The logstash configuration for the dropwizard stats is as follows:

    input {
      dropwizard_metrics_stats { } 
    }

The above will by default connect to localhost on port 8081, you can change this by specify the url
it should connect to, to obtain the dropwizard metrics:

    input {
        dropwizard_metrics_stats {
           url => "http://localhost:9081/metrics"
        }
    }

Various parts of the plugin can be configured such as the polling period, and the request timeout for the metrics http request

    input {
        dropwizard_metrics_stats {
           url => "http://localhost:9081/metrics"
           store_all_keys => true
           poll_period_s => 1
           request_timeout_s => 1            
        }
    }


The above configuration connects to a dropwizard application and the events that will be output will be 
similar to the following:

    {  
        "message":"|gaugesjvmgcpsmarksweepcountvalue=1|gaugesjvmgcpsmarksweeptimevalue=65|gaugesjvmgcpsscavengecountvalue=4|gaugesjvmgcpsscavengetimevalue=88|gaugesjvmmemoryheapcommittedvalue=503316480|gaugesjvmmemoryheapinitvalue=536870912|gaugesjvmmemoryheapmaxvalue=503316480|gaugesjvmmemoryheapusagevalue=0.28561333020528157|gaugesjvmmemoryheapusedvalue=143753896|gaugesjvmmemorynonheapcommittedvalue=54165504|gaugesjvmmemorynonheapinitvalue=2555904|gaugesjvmmemorynonheapmaxvalue=-1|gaugesjvmmemorynonheapusagevalue=-53151384.0|gaugesjvmmemorynonheapusedvalue=53151384|gaugesjvmmemorypoolscodecacheusagevalue=0.06961390177408854|gaugesjvmmemorypoolscompressedclassspaceusagevalue=0.003796711564064026|gaugesjvmmemorypoolsmetaspaceusagevalue=0.9771751430904363|gaugesjvmmemorypoolspsedenspaceusagevalue=0.6016255219777426|gaugesjvmmemorypoolspsoldgenusagevalue=0.06402626633644104|gaugesjvmmemorypoolspssurvivorspaceusagevalue=0.16223669052124023|gaugesjvmmemorytotalcommittedvalue=557481984|gaugesjvmmemorytotalinitvalue=539426816|gaugesjvmmemorytotalmaxvalue=503316479|gaugesjvmmemorytotalusedvalue=196905280|",
        "@version":"1",
        "@timestamp":"2014-09-28T16:43:26.724Z",
        "gaugesjvmgcpsmarksweepcountvalue":1.0,
        "gaugesjvmgcpsmarksweeptimevalue":65.0,
        "gaugesjvmgcpsscavengecountvalue":4.0,
        "gaugesjvmgcpsscavengetimevalue":88.0,
        "gaugesjvmmemoryheapcommittedvalue":503316480.0,
        "gaugesjvmmemoryheapinitvalue":536870912.0,
        "gaugesjvmmemoryheapmaxvalue":503316480.0,
        "gaugesjvmmemoryheapusagevalue":0.28561333020528157,
        "gaugesjvmmemoryheapusedvalue":143753896.0,
        "gaugesjvmmemorynonheapcommittedvalue":54165504.0,
        "gaugesjvmmemorynonheapinitvalue":2555904.0,
        "gaugesjvmmemorynonheapmaxvalue":-1.0,
        "gaugesjvmmemorynonheapusagevalue":-53151384.0,
        "gaugesjvmmemorynonheapusedvalue":53151384.0,
        "gaugesjvmmemorypoolscodecacheusagevalue":0.06961390177408854,
        "gaugesjvmmemorypoolscompressedclassspaceusagevalue":0.003796711564064026,
        "gaugesjvmmemorypoolsmetaspaceusagevalue":0.9771751430904363,
        "gaugesjvmmemorypoolspsedenspaceusagevalue":0.6016255219777426,
        "gaugesjvmmemorypoolspsoldgenusagevalue":0.06402626633644104,
        "gaugesjvmmemorypoolspssurvivorspaceusagevalue":0.16223669052124023,
        "gaugesjvmmemorytotalcommittedvalue":557481984.0,
        "gaugesjvmmemorytotalinitvalue":539426816.0,
        "gaugesjvmmemorytotalmaxvalue":503316479.0,
        "gaugesjvmmemorytotalusedvalue":196905280.0,
        "host":"localhost.localdomain",
        "type":"metricstats",
        "metricshost":"localhost",
        "metricsport":8081
    }

Note the dropwizard metric stats are contained within the "message" event (field), but by default the plugin configuration also makes available as events the jvm memory and gc gauges from the dropwizard json.

If you wish to have the plugin just make available all the available metrics only in the `message` field, for use in custom filtering (via a `filter`), then you can specify the following:

    input {
      dropwizard_metrics_stats {    
        regexp_include_keys => [ ]
        store_all_keys => false
      }
    }

This means you will need to use a custom filter to extract the values you wish to be indexed and searchable (and graphable in kibana).  For example, the following extracts one event `gaugesjvmmemoryheapcommittedvalue`

    input {
      dropwizard_metrics_stats {
        url => "http://localhost:9081/metrics"
        regexp_include_keys => [ ]
        store_all_keys => false
        type => "dropwizardstats"
      }
    }
    filter {
      if [type] == "dropwizardstats" {
        grok {
            match => [ "message", ".*gaugesjvmmemoryheapcommittedvalue=%{NUMBER:gaugesjvmmemoryheapcommittedvalue:int}\|.*" ]
        }
      }
    }
    output { 
        elasticsearch_http { 
            host => "localhost" 
        }  
    }
    

When stored in elasticsearch the document will look as follows:

    {
        _index: logstash-2014.09.28
        _type: dropwizardstats
        _id: S4X1qNh1SWmh0qRLfpiheA
        _version: 1
        _score: 1
        _source: {
            message: |countersiodropwizardjettymutableservletcontexthandleractivedispatchescount=0|countersiodropwizardjettymutableservletcontexthandleractiverequestscount=0|countersiodropwizardjettymutableservletcontexthandleractivesuspendedcount=0|gaugesjvmbuffersdirectcapacityvalue=330013|gaugesjvmbuffersdirectcountvalue=45|gaugesjvmbuffersdirectusedvalue=330013|gaugesjvmbuffersmappedcapacityvalue=0|gaugesjvmbuffersmappedcountvalue=0|gaugesjvmbuffersmappedusedvalue=0|gaugesjvmgcpsmarksweepcountvalue=1|gaugesjvmgcpsmarksweeptimevalue=65|gaugesjvmgcpsscavengecountvalue=5|gaugesjvmgcpsscavengetimevalue=96|gaugesjvmmemoryheapcommittedvalue=503316480|gaugesjvmmemoryheapinitvalue=536870912|gaugesjvmmemoryheapmaxvalue=503316480|gaugesjvmmemoryheapusagevalue=0.2541093349456787|gaugesjvmmemoryheapusedvalue=127897416|gaugesjvmmemorynonheapcommittedvalue=55738368|gaugesjvmmemorynonheapinitvalue=2555904|gaugesjvmmemorynonheapmaxvalue=-1|gaugesjvmmemorynonheapusagevalue=-54781016.0|gaugesjvmmemorynonheapusedvalue=54781016|gaugesjvmmemorypoolscodecacheusagevalue=0.07531967163085937|gaugesjvmmemorypoolscompressedclassspaceusagevalue=0.003798171877861023|gaugesjvmmemorypoolsmetaspaceusagevalue=0.9831256837423896|gaugesjvmmemorypoolspsedenspaceusagevalue=0.4924901450552591|gaugesjvmmemorypoolspsoldgenusagevalue=0.06405678391456604|gaugesjvmmemorypoolspssurvivorspaceusagevalue=0.14417076110839844|gaugesjvmmemorytotalcommittedvalue=559054848|gaugesjvmmemorytotalinitvalue=539426816|gaugesjvmmemorytotalmaxvalue=503316479|gaugesjvmmemorytotalusedvalue=182678432|gaugesjvmthreadsblockedcountvalue=0|gaugesjvmthreadscountvalue=54|gaugesjvmthreadsdaemoncountvalue=5|gaugesjvmthreadsnewcountvalue=0|gaugesjvmthreadsrunnablecountvalue=9|gaugesjvmthreadsterminatedcountvalue=0|gaugesjvmthreadstimed_waitingcountvalue=12|gaugesjvmthreadswaitingcountvalue=33|gaugesorgapachehttpconnclientconnectionmanagersdfewebappavailableconnectionsvalue=0|gaugesorgapachehttpconnclientconnectionmanagersdfewebappleasedconnectionsvalue=0|gaugesorgapachehttpconnclientconnectionmanagersdfewebappmaxconnectionsvalue=1024|gaugesorgapachehttpconnclientconnectionmanagersdfewebapppendingconnectionsvalue=0|gaugesorgeclipsejettyutilthreadqueuedthreadpooldwjobsvalue=0|gaugesorgeclipsejettyutilthreadqueuedthreadpooldwsizevalue=8|gaugesorgeclipsejettyutilthreadqueuedthreadpooldwutilizationvalue=0.375|meterschqoslogbackcoreappenderallcount=1834|meterschqoslogbackcoreappenderallm15_rate=0.009686243158634386|meterschqoslogbackcoreappenderallm1_rate=1.0699198115610356e-40|meterschqoslogbackcoreappenderallm5_rate=4.104658511050309e-08|meterschqoslogbackcoreappenderallmean_rate=0.3113302300883666|meterschqoslogbackcoreappenderallunits=events/second|meterschqoslogbackcoreappenderdebugcount=1059|meterschqoslogbackcoreappenderdebugm15_rate=0.002517107911457814|meterschqoslogbackcoreappenderdebugm1_rate=6.186432330193877e-41|meterschqoslogbackcoreappenderdebugm5_rate=1.739179870004009e-08|meterschqoslogbackcoreappenderdebugmean_rate=0.1797703784232393|meterschqoslogbackcoreappenderdebugunits=events/second|meterschqoslogbackcoreappendererrorcount=755|....|timersorgeclipsejettyserverhttpconnectionfactory9081connectionsrate_units=calls/second|timersorgeclipsejettyserverhttpconnectionfactory9081connectionsstddev=0.01512661719088467|
            @version: 1
            @timestamp: 2014-09-28T20:01:56.789Z
            host: localhost.localdomain
            type: dropwizardstats
            metricshost: localhost
            metricsport: 9081
            gaugesjvmmemoryheapcommittedvalue: 503316480
        }
    }    


By default the plugin creates the events under the type `metricstats`.  You can change this by specifying the `type` element
in the input:

    input {
      dropwizard_metrics_stats {
        url => "http://localhost:9081/metrics"
        regexp_include_keys => [ ]
        store_all_keys => false
        type => "dropwizardstats"
      }
    }
    
### Extracting all stats as searchable fields ###
    
Rather than having to configure a filter, you can have the input extract all the metrics as searchable fields for you,
by setting `true` for the `store_all_keys` option, and by setting the regexp includes to an empty array:
    
    input { 
        dropwizard_metrics_stats { 
            regexp_include_keys => [ ]
        } 
    }
    output { 
        elasticsearch_http { 
            host => "localhost" 
        }  
    } 
    
This will extract all elements.  If you don't want some of the fields use either the `regexp_include_keys` or `regexp_exclude_keys` configuration option.  Both are an array of regular expressions that match the key name.
By default the plugin has set the following `regexp_include_keys`:

    input { 
        dropwizard_metrics_stats { 
            regexp_include_keys => [ "^gaugesjvmmemory.*$", "^gaugesjvmgc.*$", "^gaugejvmthreads.*$" ]
        } 
    }
    
    
### Polling Frequency ###
    
By default the input will poll the dropwizard metrics admin endpoing every second.  To reduce or increase this frequency you can use the `poll_period_s` configuration option.  The following will poll every 0.5 seconds (500 millis):


    input { 
        dropwizard_metrics_stats { 
            poll_period_s  => 0.5
        } 
    }    
    
### Specifying the metrics admin endpoint ###
    
By default the input will connect to the localhost on port 8081 and hit /metrics (http://localhost:8081/metrics).  To change this use the configuration option `url`:
    
    input { 
        dropwizard_metrics_stats { 
            poll_period_s  => 0.5
            url => "http://localhost:9081/metrics"
        } 
    }
    
### Specifying the key and value separator ###

By default the separator in the message for the statistic name and value is `=`.  To specify a different separator you
can use the configuration option `value_separator`:

    input { 
        dropwizard_metrics_stats { 
            poll_period_s  => 0.5
            url => "http://localhost:9081/metrics"
            value_separator=> ":"
        } 
    }
    
    
### Specifying the delimeter between the different stats ###
    
By default the separator between the differing stats in the message field is '|'.  To specify a different separator you
can use the configuration option `stat_separator`.

    input { 
        dropwizard_metrics_stats { 
            poll_period_s  => 0.5
            url => "http://localhost:9081/metrics"
            value_separator=> ":"
            stat_separator => ","
        } 
    }


### Retry on Connection Failure ###

The plugin will attempt to reconnect to the dropwizard application incase of a connection failure between the persistent connection from the plugin and the dropwizard application.  By default the delay between retrying a connection to the app is 5 seconds (i.e. it will attempt to reconnect to the dropwizard app every 5seconds).  To change this you can use the configuration option `reconnect_period_s`:

    input { 
        dropwizard_metrics_stats { 
            value_separator=> ":"
            stat_separator => ","
            reconnect_period_s => 10
        } 
    }

    
## Installation ##
    
The input ruby script (`'dropwizard_metrics_stats.rb`) should be installed in `logstash/inputs/`.  This is either in your plugins location, or within your logstash distribution in `lib/logstash/inputs/`.  For example:

    bin/logstash --pluginpath /Users/dominictootell/git/logstash_dropwizard_metrics_stats -e \
    'input { dropwizard_metrics_stats { type => "dropwizard_stats" poll_period_s => 0.5 } } 
    output { stdout { codec => rubydebug } }'    


## Example kibana tracking ##

## License ##

Apache v2, See LICENSE file