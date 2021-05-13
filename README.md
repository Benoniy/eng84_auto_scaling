# Auto Scaling
## Scaling:  
![Scaling Image](https://github.com/Benoniy/eng84_auto_scaling/blob/main/images/scaling.png)  


* Vertical Scaling   - The process of increasing the capability of a single machine in order to fulfill greater 
  demand.  
  

* Horizontal Scaling - The process of increasing the amount of machines to distribute demand across them.  


## Load Balancers:  
Earlier I said that demand could be distributed among several machines, this is usually achieved by using a load 
balancer.


![Scaling Image](https://github.com/Benoniy/eng84_auto_scaling/blob/main/images/load_balancers.png)


* Application Load Balancer - This balancer is used to create HTTP and HTTPS access points with dynamic port mapping,
  it's useful for webservers as it examines the contents of the HTTP/S request to determine where to route it.


* Network Load Balancer - This balancer is used to create TCP and SSL access points with dynamic port mapping, it's 
  useful when the connection should be able to handle a large amount of requests, it does not perform content aware 
  routing and does not check the status of the servers that it is talking to in a fully accurate way.


* Classic Load Balancer - This balancer is functionally a combination of the two previous load balancers. It's fairly 
  depreciated, and amazon discourages the use of it excluding for legacy purposes.  
  

## Route 53:  
![Scaling Image](https://github.com/Benoniy/eng84_auto_scaling/blob/main/images/route53.png)
