public class VisionApiResponse
{
    public List<VisionResponse>? Responses { get; set; }
}

public class VisionResponse
{
    public List<LabelAnnotation>? LabelAnnotations { get; set; }
}

public class LabelAnnotation
{
    public string Description { get; set; }
}