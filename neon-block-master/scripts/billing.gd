extends Node
## Only the Android bridge verifies Play-signed purchases. Desktop never simulates payment.
signal changed
signal message(code: String)
const PLUS := "neon_plus"
const PACK := "rescue_pack_10_20"
var native: Object
var products: Dictionary = {}
var state := "starting"
var busy := false
var configured := false
var pending := false
var restoring := false

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	if native!=null: return
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/billing_config.json"))
	configured = config is Dictionary and not str(config.get("public_key_base64","")).strip_edges().is_empty()
	if OS.get_name()!="Android":
		state = "android_only"
	elif not configured:
		state = "configuration_required"
	elif not Engine.has_singleton("NeonBilling"):
		state = "unavailable"
	else:
		native = Engine.get_singleton("NeonBilling")
		native.connect("billing_event",_native_event)
		native.start(str(config.public_key_base64))
	changed.emit()

func price(id: String) -> String:
	return str(products.get(id,{}).get("price",""))

func available(id: String) -> bool:
	return native!=null and state=="ready" and not busy and products.has(id) and not price(id).is_empty()

func purchase(id: String, gate: RefCounted, answer: String) -> bool:
	if not available(id) or not id in [PLUS,PACK]: return false
	if gate==null or not gate.accept(answer): return false
	if id==PLUS and Store.data.neon_plus: return false
	busy = true
	changed.emit()
	native.buy(id)
	return true

func restore() -> void:
	if native==null:
		message.emit(state)
		return
	restoring = true
	native.restore()

func _native_event(payload: String) -> void:
	var event = JSON.parse_string(payload)
	if not event is Dictionary: return
	match event.get("type",""):
		"connected":
			state = "ready"
		"catalog":
			products.clear()
			for product in event.get("products",[]):
				if product is Dictionary and product.get("id","") in [PLUS,PACK] and product.get("price","") is String:
					products[product.id] = product
		"verified":
			var id: String = str(event.get("id",""))
			var receipt: String = str(event.get("receipt",""))
			var already_delivered: bool = receipt in Store.data.billing_receipts
			# Save the entitlement and receipt atomically BEFORE asking Play to consume/ack.
			if Store.apply_verified_purchase(id,receipt):
				native.finish(receipt)
				if not already_delivered: message.emit("delivered")
			else:
				busy = false
				message.emit("save_failed")
		"ownership":
			# A successful authoritative query can revoke a refunded permanent product.
			# Offline/error responses never remove a cached entitlement.
			if event.get("plus",true)==false: Store.revoke_neon_plus()
			pending = event.get("pending",false)==true
			busy = false
			if restoring: message.emit("restored")
			restoring = false
		"settled":
			busy = false
			pending = false
		"pending":
			busy = false
			pending = true
			message.emit("pending")
		"cancelled":
			busy = false
			message.emit("cancelled")
		"error":
			busy = false
			restoring = false
			var code: String = str(event.get("code","unavailable"))
			if code in ["configuration_required","disconnected"]: state = code
			message.emit(code)
	changed.emit()
