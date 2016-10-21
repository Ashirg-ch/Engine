using Gee;

public abstract class RenderTarget : Object
{
    private const bool SINGLE_THREADED = true;

    private RenderState? current_state = null;
    private RenderState? buffer_state = null;
    private bool running = false;
    private Mutex state_mutex = Mutex();

    private bool initialized = false;
    private bool init_status;
    private Mutex init_mutex = Mutex();

    private Mutex resource_mutex = Mutex();
    private uint handle_model_ID = 1;
    private uint handle_texture_ID = 1;
    private uint handle_label_ID = 1;
    private ArrayList<ResourceModel> to_load_models = new ArrayList<ResourceModel>();
    private ArrayList<ResourceTexture> to_load_textures = new ArrayList<ResourceTexture>();
    private ArrayList<IModelResourceHandle> handles_models = new ArrayList<IModelResourceHandle>();
    private ArrayList<ITextureResourceHandle> handles_textures = new ArrayList<ITextureResourceHandle>();
    private ArrayList<ILabelResourceHandle> handles_labels = new ArrayList<ILabelResourceHandle>();

    private bool saved_v_sync = false;
    private string saved_shader_3D;
    private string saved_shader_2D;

    protected IWindowTarget window;
    protected ResourceStore store;

    public RenderTarget(IWindowTarget window)
    {
        this.window = window;
        anisotropic_filtering = true;
        v_sync = saved_v_sync;
    }

    ~RenderTarget()
    {
        stop();
    }

    public void set_state(RenderState state)
    {
        state_mutex.lock();
        buffer_state = state;
        state_mutex.unlock();

        if (SINGLE_THREADED)
            render_cycle(buffer_state);
    }

    public bool start()
    {
        if (SINGLE_THREADED)
            return init();

        Threading.start0(render_thread);

        while (true)
        {
            init_mutex.lock();
            if (initialized)
            {
                init_mutex.unlock();
                break;
            }
            init_mutex.unlock();

            window.pump_events();
            Thread.usleep(10000);
        }

        return init_status;
    }

    public void stop()
    {
        running = false;
    }

    public uint load_model(ResourceModel obj)
    {
        resource_mutex.lock();
        to_load_models.add(obj);
        uint ret = handle_model_ID++;
        resource_mutex.unlock();

        return ret;
    }

    public uint load_texture(ResourceTexture texture)
    {
        resource_mutex.lock();
        to_load_textures.add(texture);
        uint ret = handle_texture_ID++;
        resource_mutex.unlock();

        return ret;
    }

    public uint load_label(ResourceLabel label)
    {
        resource_mutex.lock();
        handles_labels.add(create_label(label));
        uint ret = handle_label_ID++;
        resource_mutex.unlock();

        return ret;
    }

    protected IModelResourceHandle? get_model(uint handle)
    {
        resource_mutex.lock();
        IModelResourceHandle ret = (handle > handles_models.size || handle <= 0) ? null : handles_models[(int)handle - 1];
        resource_mutex.unlock();

        return ret;
    }

    protected ITextureResourceHandle? get_texture(uint handle)
    {
        resource_mutex.lock();
        ITextureResourceHandle? ret = (handle > handles_textures.size || handle <= 0) ? null : handles_textures[(int)handle - 1];
        resource_mutex.unlock();

        return ret;
    }

    protected ILabelResourceHandle? get_label(uint handle)
    {
        resource_mutex.lock();
        ILabelResourceHandle? ret = (handle > handles_labels.size || handle <= 0) ? null : handles_labels[(int)handle - 1];
        resource_mutex.unlock();

        return ret;
    }

    private void render_thread()
    {
        init_status = init();
        init_mutex.lock();
        initialized = true;
        init_mutex.unlock();

        if (!init_status)
            return;

        running = true;

        while (running)
        {
            state_mutex.lock();
            if (current_state == buffer_state)
            {
                state_mutex.unlock();
                Thread.usleep(1000);
                continue;
            }

            current_state = buffer_state;
            state_mutex.unlock();

            render_cycle(current_state);

            // TODO: Fix fullscreen v-sync issues
        }
    }

    private void render_cycle(RenderState state)
    {
        load_resources();
        check_settings();
        prepare_state_internal(state);
        render(state);
        window.swap();
    }

    private void load_resources()
    {
        resource_mutex.lock();
        while (to_load_models.size != 0)
        {
            ResourceModel model = to_load_models.remove_at(0);
            resource_mutex.unlock();
            handles_models.add(do_load_model(model));
            resource_mutex.lock();
        }

        while (to_load_textures.size != 0)
        {
            ResourceTexture texture = to_load_textures.remove_at(0);
            resource_mutex.unlock();
            handles_textures.add(do_load_texture(texture));
            resource_mutex.lock();
        }
        resource_mutex.unlock();
    }

    private void check_settings()
    {
        bool new_v_sync = v_sync;

        if (new_v_sync != saved_v_sync)
        {
            saved_v_sync = new_v_sync;
            change_v_sync(saved_v_sync);
        }

        string new_shader_3D = shader_3D;

        if (new_shader_3D != saved_shader_3D)
        {
            saved_shader_3D = new_shader_3D;
            change_shader_3D(saved_shader_3D);
        }

        string new_shader_2D = shader_2D;

        if (new_shader_2D != saved_shader_2D)
        {
            saved_shader_2D = new_shader_2D;
            change_shader_2D(saved_shader_2D);
        }
    }

    private void prepare_state_internal(RenderState state)
    {
        foreach (RenderScene scene in state.scenes)
        {
            if (scene is RenderScene2D)
            {
                RenderScene2D s = scene as RenderScene2D;
                foreach (RenderObject2D obj in s.objects)
                {
                    if (obj is RenderLabel2D)
                    {
                        RenderLabel2D label = obj as RenderLabel2D;
                        ILabelResourceHandle handle = get_label(label.reference.handle);

                        bool invalid = false;
                        if (!handle.created ||
                            label.font_type != handle.font_type ||
                            label.font_size != handle.font_size ||
                            label.text != handle.text)
                            invalid = true;

                        if (!invalid)
                            continue;

                        LabelBitmap bitmap = store.generate_label_bitmap(label);
                        do_load_label(handle, bitmap);

                        handle.created = true;
                        handle.font_type = label.font_type;
                        handle.font_size = label.font_size;
                        handle.text = label.text;
                    }
                }
            }
            else if (scene is RenderScene3D)
            {
                RenderScene3D s = scene as RenderScene3D;
                foreach (Transformable3D obj in s.objects)
                {
                    if (obj is RenderLabel3D)
                    {
                        RenderLabel3D label = obj as RenderLabel3D;
                        ILabelResourceHandle handle = get_label(label.reference.handle);

                        bool invalid = false;
                        if (!handle.created ||
                            label.font_type != handle.font_type ||
                            label.font_size != handle.font_size ||
                            label.text != handle.text)
                            invalid = true;

                        if (!invalid)
                            continue;

                        LabelBitmap bitmap = store.generate_label_bitmap_3D(label);
                        do_load_label(handle, bitmap);

                        handle.created = true;
                        handle.font_type = label.font_type;
                        handle.font_size = label.font_size;
                        handle.text = label.text;
                    }
                }
            }
        }
    }

    public Mat4 get_projection_matrix(float view_angle, float aspect_ratio)
    {
        view_angle  *= 0.6f;
        float z_near = 0.5f * aspect_ratio;
        float z_far  =   30 * aspect_ratio;

        float vtan1 = 1 / (float)Math.tan(view_angle);
        float vtan2 = vtan1 * aspect_ratio;
        Vec4 v1 = {vtan1,    0,                   0,                                    0};
        Vec4 v2 = {0,        vtan2,               0,                                    0};
        Vec4 v3 = {0,        0,                   -(z_far + z_near) / (z_far - z_near), -2 * z_far * z_near / (z_far - z_near)};
        Vec4 v4 = {0,        0,                   -1,                                   0};

        return new Mat4.with_vecs(v1, v2, v3, v4);
    }

    public abstract void render(RenderState state);

    protected abstract bool init();
    protected abstract IModelResourceHandle do_load_model(ResourceModel model);
    protected abstract ITextureResourceHandle do_load_texture(ResourceTexture texture);
    protected abstract void do_load_label(ILabelResourceHandle handle, LabelBitmap bitmap);
    protected abstract ILabelResourceHandle create_label(ResourceLabel label);
    protected abstract void change_v_sync(bool v_sync);
    protected abstract bool change_shader_3D(string name);
    protected abstract bool change_shader_2D(string name);

    public ResourceStore resource_store { get { return store; } }
    public bool v_sync { get; set; }
    public bool anisotropic_filtering { get; set; }
    public string shader_3D { get; set; }
    public string shader_2D { get; set; }
}
