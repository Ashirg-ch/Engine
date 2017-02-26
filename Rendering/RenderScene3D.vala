using Gee;

public abstract class RenderScene : Object {}

public class RenderScene3D : RenderScene
{
    private ArrayList<Transformable3D> objs = new ArrayList<Transformable3D>();
    private ArrayList<LightSource> _lights = new ArrayList<LightSource>();
    private bool copy_state;

    public RenderScene3D(bool copy_state, Size2i screen_size, float scene_aspect_ratio, Rectangle rect)
    {
        this.copy_state = copy_state;
        this.rect = rect;
        this.screen_size = screen_size;

        focal_length = 1;

        Vec3 scene_translation = Vec3
        (
            (rect.x + rect.width  / 2 - screen_size.width  / 2) * 2 / screen_size.width,
            (rect.y + rect.height / 2 - screen_size.height / 2) * 2 / screen_size.height,
            0
        );

        float max_w = rect.width  / screen_size.height / scene_aspect_ratio; // Screen height just to simplify away the screen aspect ratio
        float max_h = rect.height / screen_size.height;

        float scale = float.min(max_w, max_h);
        scale = float.max(scale, 0);

        scene_transform = Calculations.scale_matrix(Vec3(scale, scale, scale)).mul_mat(Calculations.translation_matrix(scene_translation));

        set_camera(new Camera());
    }

    public void add_object(Transformable3D object)
    {
        objs.add(copy_state ? object.copy() : object);
    }

    public void add_light_source(LightSource light)
    {
        _lights.add(copy_state ? light.copy() : light);
    }

    public void set_camera(Camera camera)
    {
        view_transform = camera.get_view_transform();
        camera_position = camera.position;
        focal_length = camera.focal_length;
    }

    public ArrayList<Transformable3D> objects { get { return objs; } }
    public ArrayList<LightSource> lights { get { return _lights; } }
    public Mat4 scene_transform { get; private set; }
    public Mat4 view_transform { get; private set; }
    public Vec3 camera_position { get; private set; }
    public float focal_length { get; private set; }
    public Rectangle rect { get; private set; }
    public Size2i screen_size { get; private set; }
}
