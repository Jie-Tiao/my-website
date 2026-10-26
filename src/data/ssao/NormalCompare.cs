using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
[ImageEffectAllowedInSceneView]
public class NormalCompare : MonoBehaviour
{
    private Camera cam;
    private Material material;
    private RenderingPath previousPath;
    public bool isDeffered;
    private void OnEnable()
    {
        cam = GetComponent<Camera>();
        previousPath = cam.renderingPath;
        ApplyRenderingPath();
        Shader shader = Shader.Find("SSAO/NormalCompare");
        if (shader != null && shader.isSupported)
            material = new Material(shader) { hideFlags = HideFlags.HideAndDontSave };
    }
    // Unity prepares render targets before OnPreCull. Apply path changes earlier.
    private void Update() { ApplyRenderingPath(); }
    private void OnValidate()
    {
        if (isActiveAndEnabled) ApplyRenderingPath();
    }
    private void ApplyRenderingPath()
    {
        if (cam == null) cam = GetComponent<Camera>();
        if (cam != null)
            cam.renderingPath = isDeffered ? RenderingPath.DeferredShading : RenderingPath.Forward;
    }
    private void OnPreCull()
    {
        cam.depthTextureMode |= DepthTextureMode.Depth | DepthTextureMode.DepthNormals;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null) Graphics.Blit(source, destination);
        else
        {
            material.SetMatrix("_NormalToWorld", cam.worldToCameraMatrix.inverse);
            Graphics.Blit(source, destination, material,
                cam.actualRenderingPath == RenderingPath.DeferredShading ? 1 : 0);
        }
    }
    private void OnDisable()
    {
        if (cam != null) cam.renderingPath = previousPath;
        if (material != null)
        {
            if (Application.isPlaying) Destroy(material);
            else DestroyImmediate(material);
        }
        material = null;
    }
}
