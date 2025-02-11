namespace cqrs.ui.models {
    public class AesKey {
        public string   id          { get; set; } = String.Empty;
        public string   keyId       { get; set; } = String.Empty;
        public string   key         { get; set; } = String.Empty;
        public bool     fromCache   { get; set; } = false;
        public string   readHost    { get; set; } = String.Empty;
        public string   writeHost   { get; set; } = String.Empty;
        public string   readRegion  { get; set; } = String.Empty;
        public string   writeRegion { get; set; } = String.Empty;
        public string   timeStamp   { get; set; } = String.Empty;
    }
}