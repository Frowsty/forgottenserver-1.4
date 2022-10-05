function onUpdateDatabase()
	print("> Updating database to version 31 (Character Stats)")
	db.query("ALTER TABLE players ADD `stat_str` TINYINT UNSIGNED DEFAULT 0")
	db.query("ALTER TABLE players ADD `stat_int` TINYINT UNSIGNED DEFAULT 0")
	db.query("ALTER TABLE players ADD `stat_dex` TINYINT UNSIGNED DEFAULT 0")
	db.query("ALTER TABLE players ADD `stat_vit` TINYINT UNSIGNED DEFAULT 0")
	db.query("ALTER TABLE players ADD `stat_spr` TINYINT UNSIGNED DEFAULT 0")
	db.query("ALTER TABLE players ADD `stat_wis` TINYINT UNSIGNED DEFAULT 0")
	return true
end
