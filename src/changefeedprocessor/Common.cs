public class Common
{
    public const string redisConnectionString = "redisConnectionString";
    public const string cosmosdbConnectionString = "COSMOSDB_CONNECTIONSTRING";
    public const string cosmosdbDatabase = "AesKeys";
    public const string cosmosdbContainer = "Items";
}

    public class AesKey 
    {
        public string keyId { get; set; }
        public string key { get; set; }

        public bool fromCache  { get; set; }
        public string readHost  { get; set; }
        public string writeHost  { get; set; }
        public string readRegion  { get; set; }
        public string writeRegion  { get; set; }
        public string timeStamp { get; set; }
    }