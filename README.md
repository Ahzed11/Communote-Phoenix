# Communote

## Initialization 
```
docker-compose up
docker-compose run web mix ecto.create
docker-compose run web mix ecto.migrate
```

Now you can visit:
- [`localhost:4000`](http://localhost:4000) from your browser to access the website.
- [`localhost:9001`](http://localhost:9011) from your browser to access minio (used to replace S3 locally)
    1. Connect with `admin` as username and `password` as password
    2. Create a bucket named `communote`
