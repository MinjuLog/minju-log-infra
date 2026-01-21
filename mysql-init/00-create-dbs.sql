-- root로 실행됨

CREATE DATABASE IF NOT EXISTS minjulog
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS minjulog_feed
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- compose에서 만든 일반 유저에게 두 DB 권한 부여
GRANT ALL PRIVILEGES ON minjulog.* TO minju@'%';
GRANT ALL PRIVILEGES ON minjulog_feed.* TO minju@'%';

FLUSH PRIVILEGES;