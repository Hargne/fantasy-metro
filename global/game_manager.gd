extends Node

const uuid = preload("res://global/uuid.gd")

export var version = "0.0.1-alpha"

export(int) var level = 0
export(int) var difficulty = 0
export(String) var guid = ""

func init_game(lvl, diff):
    level = lvl 
    difficulty = diff
    guid = uuid.v4()