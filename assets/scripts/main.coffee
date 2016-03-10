require '../../bower_components/angular/angular.js'
require '../../bower_components/angular-websocket/angular-websocket.js'
Chart = require '../../bower_components/Chart.js/Chart.js'
_ = require '../../bower_components/lodash/lodash'

module = angular.module 'CO2Info', [
    'ngWebSocket'
]

module.value 'currentMeasures', {
  co2: 0
  temp: 0
}

module.factory 'promiseMeasures', [
  '$websocket'
  '$q'
  'currentMeasures'
  ($ws, $q, currentMeasures)->
    defer = do $q.defer
    stream = $ws 'ws://192.168.2.163:8888/sock/'
    
    # Handlers for events
    handlers = {}
    handlers.history = (data)-> defer.resolve data
    handlers.measures = (data)-> currentMeasures[data.tp] = data.val

    # Message listner
    stream.onMessage (event)->
      emit = JSON.parse event.data
      [event, data] = emit
      handlers[event]?(data)
    defer.promise
]

###
module.factory 'MockMeasures', [
  '$timeout'
  ($timeout)->
    measures = 
      temp: 18
      co2: 600

    req = ->
      measures.temp += _.random -2.0,2.0
      measures.co2 += _.random -20,20
      $timeout req, _.random 200,4000
    do req
    measures
]
###

module.directive 'measureRenderer', [
  'promiseMeasures'
  (promiseMeasures)->
    SIZE = 50
    UPDATE_INTERVAL = 2000

    template: """
    <div ng-class="widgetCssClass">
      <canvas></canvas>
    </div>
    """
    scope:
      name: '@measureRenderer'
    controller: ['$scope', '$element','currentMeasures', ($scope, $element, currentMeasures)->
      $scope.widgetCssClass="widget__#{$scope.name}"
      $scope.measures = currentMeasures
    ]
    link: (scope, iElem)->
      canvasDom = iElem.find('canvas')[0]
      canvasDom.id = "w#{scope.name}"
      promiseMeasures.then (initial)->
        canvasDom.width = 600
        canvasDom.height = 400
        ctx = canvasDom.getContext '2d'
        chart = new Chart(ctx).Line(
          {
            labels: ('' for i in initial[scope.name])
            datasets:[
              {
              label: scope.name
              data: initial[scope.name]
              }
            ]
          }
        )
        scope.measures[scope.name] = _.last initial[scope.name]
        cnt = SIZE
        setInterval ->
          chart.removeData()
          chart.addData [scope.measures[scope.name]], ''
        , UPDATE_INTERVAL
]

# finally
angular.bootstrap document, [module.name]
