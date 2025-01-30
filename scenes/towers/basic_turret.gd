extends BaseTower

@export var damage: int = 10
@export var range: float = 4.0
@export var fire_rate: float = 1.0  # shots per second

var time_since_last_shot: float = 0.0

func _ready():
    cost = 100
    power_usage = 5  # per shot
    durability = 100

func _process(delta):
    time_since_last_shot += delta
    if time_since_last_shot >= 1.0 / fire_rate:
        # Try to fire if we have a target and power
        attempt_fire()

func attempt_fire() -> void:
    # Check if we have power and a target
    # This will be implemented when we add the targeting system
    pass

func get_attack_range() -> float:
    return range

func get_damage() -> int:
    return damage