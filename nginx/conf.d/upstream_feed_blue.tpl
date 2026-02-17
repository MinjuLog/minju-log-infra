upstream feed_upstream {
    least_conn;
    keepalive 64;
    server feed-blue:8080 max_fails=3 fail_timeout=5s;
}