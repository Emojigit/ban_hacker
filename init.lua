local mod_storage = minetest.get_mod_storage()
local worlddir = minetest.get_worldpath()
local rc = {}
rc.warn = {}
rc.warn_count = {}
rc.ban = {}
local warn_time = 5-2
local warn_second = 300
local ban_second = 300
local banip_second = 600

rc.record = function(target)
	local type = "Warn"
	if not(rc.warn_count[target]) then
		rc.warn_count[target] = 0
	end
	if rc.warn[target] and ((rc.warn[target] + warn_second) > os.time(os.date("!*t"))) then
		rc.warn_count[target] = rc.warn_count[target] + 1
	end
	rc.warn[target] = os.time(os.date("!*t"))
	if rc.warn_count[target] > warn_time then
		rc.ban[target] = os.time(os.date("!*t"))
		local type = "Ban"
	end
	minetest.log("action", "[ban_hacker] Recored `"..target.."`, type "..type..".")
	rc.save(rc.ban)
end

rc.save = function(data)
	mod_storage:set_string("ban_rc", minetest.serialize(data))
end

rc.get = function()
	return minetest.deserialize(mod_storage:get_string("ban_rc"))
end

-------------------------------------

rc.ban = rc.get() or {}

-------------------------------------

minetest.register_on_authplayer(function(name, ip, is_success)
	if not(is_success) then
		rc.record(name)
		rc.record(ip)
		minetest.log("action", "[ban_hacker] Wrong password from "..name.." ["..ip.."], recorded.")
	end
end)

minetest.register_on_prejoinplayer(function(name, ip)
	rc.ban[name] = rc.ban[name] or 0
	rc.ban[ip] = rc.ban[ip] or 0
	if ((rc.ban[name] + ban_second > os.time(os.date("!*t"))) or (rc.ban[ip] + banip_second > os.time(os.date("!*t")))) and not(ip == "127.0.0.1") then
		minetest.log("action", "[ban_hacker] Rejected connect from "..name.." ["..ip.."]")
		if (rc.ban[ip] + banip_second > os.time(os.date("!*t"))) then
			rc.record(ip)
		end
		return "Too many wrong password for this account or IP.".."\nTry again later."
	end
end)


