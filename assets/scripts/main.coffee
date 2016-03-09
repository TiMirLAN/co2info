require '../../bower_components/angular/angular.js'
#require '../../bower_components/angular-websocket/angular-websocket.js'
Chart = require '../../bower_components/Chart.js/Chart.js'
_ = require '../../bower_components/lodash/lodash'

module = angular.module 'CO2Info', [
  #  'ngWebSocket'
]

module.factory 'Measures', [
  '$websocket'
  ($ws)->
    stream = $ws 'ws://127.0.0.1:8888/sock/'
    measures = 
      temp: 0
      co2: 0
    stream.onMessage console.log.bind console
    measures
]

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

module.directive 'measureRenderer', [
  ()->
    SIZE = 50
    UPDATE_INTERVAL = 500

    template: """
    <div ng-class="widgetCssClass">
      <canvas></canvas>
    </div>
    """
    scope:
      name: '@measureRenderer'
    controller: ['$scope', '$element','MockMeasures', ($scope, $element, measures)->
      $scope.widgetCssClass="widget__#{$scope.name}"
      $scope.measures = measures
    ]
    link: (scope, iElem)->
      canvasDom = iElem.find('canvas')[0]
      canvasDom.id = "w#{scope.name}"
      canvasDom.width = 600
      canvasDom.height = 400
      ctx = canvasDom.getContext '2d'
      chart = new Chart(ctx).Line(
        {
          labels: _(1).range(SIZE).map(->'').value()
          datasets:[
            {
            label: scope.name
            data: _(1).range(SIZE).map(->0).value()
            }
          ]
        }
      )
      cnt = SIZE
      setInterval ->
        chart.removeData()
        chart.addData [scope.measures[scope.name]], ++cnt
      , UPDATE_INTERVAL
]

# finally
angular.bootstrap document, [module.name]
