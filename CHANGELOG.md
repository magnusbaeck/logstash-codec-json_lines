# 2.1.3
  - Depend on logstash-core-plugin-api instead of logstash-core, removing the need to mass update plugins on major releases of logstash
# 2.1.2
  - New dependency requirements for logstash-core for the 5.0 release
## 2.1.0
 - Backward compatible support for `Event#from_json` method https://github.com/logstash-plugins/logstash-codec-json_lines/pull/19

## 2.0.5
 - Directly use buftok to avoid indirection through the line codec https://github.com/logstash-plugins/logstash-codec-json_lines/pull/18

## 2.0.4
 - Support for customizable delimiter

## 2.0.3
 - Fixed Timestamp check in specs

## 2.0.0
 - Plugins were updated to follow the new shutdown semantic, this mainly allows Logstash to instruct input plugins to terminate gracefully,
   instead of using Thread.raise on the plugins' threads. Ref: https://github.com/elastic/logstash/pull/3895
 - Dependency on logstash-core update to 2.0

## 1.0.1
 - Improve documentation to warn about using this codec with a line oriented input.
 - light refactor of decode method
