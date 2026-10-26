using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
[ImageEffectAllowedInSceneView]
public class SSAO : MonoBehaviour
{
    private Material mat_ao, mat_blur;
    private Camera cam;
    public enum OutputMode { Composite, RawAO, FilteredAO }
    public OutputMode outputMode;
    public enum BlurMode { NormalDepthGuided, Gaussian }
    [Tooltip("Both modes use the same spatial kernel and resolution steps.")]
    public BlurMode blurMode = BlurMode.NormalDepthGuided;
    [Range(1, 128)] public int sampleCount = 20;
    [Range(0f, 0.8f)] public float radius = 0.5f;
    [Range(0f, 10f)] public float rangeCheck = 5f;
    [Range(0f, 10f)] public float aoInt = 1f;
    [Tooltip("Sample spacing in pixels; the 7-tap filter reaches 3 times this distance on each side.")]
    [Range(0f, 3f)] public float blurRadius = 1f;
    [Range(0f, 1f)] public float bilaterFilterFactor = 0.1f;
    [Min(0.001f)] public float depthSigma = 0.1f;
    [Min(0f)] public float depthBias = 0.01f;
    public Color aoColor = Color.black;
    [Tooltip("Legacy raw AO switch; Output Mode also provides filtered AO.")]
    public bool aoOnly;

    private void OnEnable()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode |= DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
        mat_ao = CreateMaterial("SSAO/SSAO");
        mat_blur = CreateMaterial("SSAO/BilateralBlur");
    }
    private static Material CreateMaterial(string name)
    {
        Shader shader = Shader.Find(name);
        return shader != null && shader.isSupported
            ? new Material(shader) { hideFlags = HideFlags.HideAndDontSave } : null;
    }
    private void OnDisable()
    {
        ReleaseMaterial(mat_ao);
        ReleaseMaterial(mat_blur);
        mat_ao = mat_blur = null;
    }
    private static void ReleaseMaterial(Material material)
    {
        if (material == null) return;
        if (Application.isPlaying) Destroy(material);
        else DestroyImmediate(material);
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mat_ao == null || mat_blur == null)
        {
            Graphics.Blit(source, destination);
            return;
        }
        cam.depthTextureMode |= DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false);
        mat_ao.SetMatrix("_VPMatrix_invers", (projection * cam.worldToCameraMatrix).inverse);
        mat_ao.SetMatrix("_VMatrix", cam.worldToCameraMatrix);
        mat_ao.SetMatrix("_NormalToWorld", cam.worldToCameraMatrix.inverse);
        mat_blur.SetMatrix("_NormalToWorld", cam.worldToCameraMatrix.inverse);
        mat_ao.SetMatrix("_PMatrix", projection);
        mat_ao.SetInt("_SampleCount", Mathf.Clamp(sampleCount, 1, 128));
        mat_ao.SetFloat("_Radius", Mathf.Max(0f, radius));
        mat_ao.SetFloat("_RangeCheck", Mathf.Max(0f, rangeCheck));
        mat_ao.SetFloat("_AOInt", Mathf.Max(0f, aoInt));
        mat_ao.SetFloat("_DepthBias", Mathf.Max(0f, depthBias));
        mat_ao.SetColor("_AOCol", aoColor);
        mat_blur.SetFloat("_BlurRadius", Mathf.Max(0f, blurRadius));
        mat_blur.SetFloat("_BilaterFilterFactor", Mathf.Clamp(bilaterFilterFactor, 0f, 0.9999f));
        mat_blur.SetFloat("_DepthSigma", Mathf.Max(depthSigma, 0.001f));
        mat_blur.SetFloat("_UseGuidance", blurMode == BlurMode.NormalDepthGuided ? 1f : 0f);
        bool deferred = cam.actualRenderingPath == RenderingPath.DeferredShading;
        mat_ao.SetFloat("_UseGBuffer", deferred ? 1f : 0f);
        mat_blur.SetFloat("_UseGBuffer", deferred ? 1f : 0f);
        if (aoOnly || outputMode == OutputMode.RawAO)
        {
            Graphics.Blit(source, destination, mat_ao, 0);
            return;
        }
        RenderTexture full = null, intermediate = null;
        try
        {
            var format = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf)
                ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
            full = RenderTexture.GetTemporary(source.width, source.height, 0, format, RenderTextureReadWrite.Linear);
            intermediate = RenderTexture.GetTemporary(source.width, source.height, 0, format, RenderTextureReadWrite.Linear);
            full.filterMode = intermediate.filterMode = FilterMode.Bilinear;
            full.wrapMode = intermediate.wrapMode = TextureWrapMode.Clamp;
            Graphics.Blit(source, full, mat_ao, 0);
            Graphics.Blit(full, intermediate, mat_blur, 0);
            Graphics.Blit(intermediate, full, mat_blur, 1);
            if (outputMode == OutputMode.FilteredAO) Graphics.Blit(full, destination);
            else
            {
                mat_ao.SetTexture("_AOTex", full);
                Graphics.Blit(source, destination, mat_ao, 1);
            }
        }
        finally
        {
            mat_ao.SetTexture("_AOTex", null);
            if (full != null) RenderTexture.ReleaseTemporary(full);
            if (intermediate != null) RenderTexture.ReleaseTemporary(intermediate);
        }
    }
}
