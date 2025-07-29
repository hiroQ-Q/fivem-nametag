CREATE TABLE IF NOT EXISTS `names` (
  `citizenid` varchar(50) NOT NULL,
  `firstname` varchar(255) NOT NULL,
  `lastname` varchar(255) NOT NULL,
  `speakstatus` VARCHAR(5) NOT NULL DEFAULT 'false',
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1;