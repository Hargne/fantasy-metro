extends Node

func connect_signal(
  signalNode: Node,
  signalMethod: String,
  receivingNode: Node,
  callbackMethod: String
) -> void:
  if signalNode.connect(signalMethod, receivingNode, callbackMethod) != OK:
    printerr("Could not connect " + signalNode.name + " -> " + signalMethod + " to " + receivingNode.name + " -> " + callbackMethod)
