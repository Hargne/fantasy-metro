extends Node2D

var rng = RandomNumberGenerator.new()
onready var mapNodeController: MapNodeController = $MapNodeController

var demandIncrementTimer: Timer
var secondsBetweenDemandIncrement = 20

func _ready():
  rng.randomize()
  setup_demand_increment_timer()

#
# Demand Increment Timer
#

func setup_demand_increment_timer() -> void:
  if demandIncrementTimer != null:
    return
  demandIncrementTimer = Timer.new()
  add_child(demandIncrementTimer)
  demandIncrementTimer.name = "DemandIncrementTimer"
  demandIncrementTimer.connect("timeout", self, "on_demand_increment_timer_timeout")
  start_demand_increment_timer(2)

func start_demand_increment_timer(time: int) -> void:
  demandIncrementTimer.wait_time = time
  demandIncrementTimer.start()
  
func on_demand_increment_timer_timeout() -> void:
  var villageNodes = mapNodeController.get_village_nodes()
  if villageNodes.size() > 0:
    for villageNode in villageNodes:
      if villageNode.can_add_resource_demand():
        var demandedResource = ResourceNode.ResourceType.values()[rng.randi() % ResourceNode.ResourceType.size()]
        villageNode.add_resource_demand(demandedResource)
  # Restart the timer
  start_demand_increment_timer(secondsBetweenDemandIncrement)
