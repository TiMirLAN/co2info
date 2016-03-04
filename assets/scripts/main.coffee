require '../../bower_components/angular/angular.js'
require '../../bower_components/angular-websocket/angular-websocket.js'
d3 = require '../../bower_components/d3/d3.js'
_ = require '../../bower_components/lodash/lodash'

module = angular.module 'CO2Info', [
  'ngWebSocket'
]

module.factory 'Measures', [
  '$websocket'
  ($ws)->
    stream = $ws 'ws://127.0.0.1:8888/sock/'
    measures = 
      temp: [1,2,3,2,5]
      co2: []
    stream.onMessage console.log.bind console
    measures
]

module.factory 'MockMeasures', [
  '$timeout'
  ($timeout)->
    measures = 
      temp: []
      co2: []

    req = ->
      measures.temp.push _.random 15,25
      $timeout req, _.random 1000,2000
    do req
    measures
]

module.directive 'measureRenderer', [
  ()->
    template: '<div class="chart"></div>'
    controller: ['$scope', '$element','MockMeasures', ($scope, $element, measures)->
      $scope.measures = measures
    ]
]

# finally
angular.bootstrap document, [module.name]
