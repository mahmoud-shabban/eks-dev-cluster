subnets = {
  public-sub-1 = {
    cidr = "10.0.1.0/24",
    az   = "us-east-1a",
  },

  public-sub-2 = {
    cidr = "10.0.2.0/24",
    az   = "us-east-1b",
  },
  private-sub-1 = {
    cidr = "10.0.3.0/24",
    az   = "us-east-1a",
  },
  private-sub-2 = {
    cidr = "10.0.4.0/24",
    az   = "us-east-1b",
} }

cluster-name    = "dev-cluster"
cluster-version = "1.31"