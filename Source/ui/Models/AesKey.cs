namespace cqrs_ui.models {
    public class AesKey {
        public string   keyId       { get; set; }
        public string   key         { get; set; }
        public string   readHost    { get; set; }
        public string   writeHost   { get; set; }
        public string   readRegion  { get; set; }
        public string   writeRegion { get; set; }
        public string   timeStamp   { get; set; }

    }
}