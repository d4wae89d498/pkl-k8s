 kubectl run -it mongo-client\
    --image=mongo\
    --rm\
    --restart=Never\
    --namespace=demo\
    --command\
    -- mongosh "mongodb://mongo-service.demo.svc.cluster.local:27017/my_database"