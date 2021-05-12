# Auto Scaling and Load Balancing using AWS Console

## Auto Scaling Group & load balancer
### Requirement's:
1. 2 Public subnets 


1. On the ec2 page select auto-scaling groups from the left bar  


2. Proceed to create a launch template using an ami


3. Once created proceed to configure settings page
   1. Select your VPC
   2. Select both of your public subnets


4. Here you can choose to attach a new load balancer
    1. We want an application load balancer for http traffic
    2. We want it to be internet-facing
    3. We want to assign our two public subnets, one to each zone   
    3. We want to create a new target group for this scaling group
    

5. From this point on its very self-explanatory


6. To locate your public dns you must find the load balancer itself!