using GL;
using Gee;

public class OpenGLShaderProgram3D
{
    private uint program;
    private OpenGLShader vertex_shader;
    private OpenGLShader fragment_shader;

    private OpenGLLightSource[] lights;

    private int vert_position_attribute;
    private int vert_texture_attribute;
    private int vert_normal_attribute;

    //private int texture_attrib = -1;
    private int projection_transform_attrib = -1;
    private int view_transform_attrib = -1;
    private int model_transform_attrib = -1;
    private int un_projection_transform_attrib = -1;
    private int un_view_transform_attrib = -1;
    private int un_model_transform_attrib = -1;
    private int light_count_attrib = -1;

    private int use_texture_attrib = -1;
    private int ambient_color_attrib = -1;
    private int diffuse_color_attrib = -1;
    private int specular_color_attrib = -1;
    private int ambient_material_attrib = -1;
    private int diffuse_material_attrib = -1;
    private int specular_material_attrib = -1;

    private int specular_exponent_attrib = -1;
    private int alpha_attrib = -1;

    public OpenGLShaderProgram3D(string name, int max_lights, int vert_position_attribute, int vert_texture_attribute, int vert_normal_attribute)
    {
        this.vert_position_attribute = vert_position_attribute;
        this.vert_texture_attribute = vert_texture_attribute;
        this.vert_normal_attribute = vert_normal_attribute;

        vertex_shader = new OpenGLShader(name + ".vert", OpenGLShader.ShaderType.VERTEX_SHADER);
        fragment_shader = new OpenGLShader(name + ".frag", OpenGLShader.ShaderType.FRAGMENT_SHADER);

        lights = new OpenGLLightSource[max_lights];

        for (int i = 0; i < lights.length; i++)
            lights[i] = new OpenGLLightSource(i);
    }

    public bool init()
    {
        if (!vertex_shader.init())
            return false;
        if (!fragment_shader.init())
            return false;

        program = glCreateProgram();

        glAttachShader(program, vertex_shader.handle);
        glAttachShader(program, fragment_shader.handle);

		//pp_texture_location = glGetUniformLocation(post_processing_shader_program, "textures");
		//bloom_attrib = glGetUniformLocation(post_processing_shader_program,"bloom");
		//vertical_attrib = glGetUniformLocation(post_processing_shader_program,"vertical");

        glBindAttribLocation(program, vert_position_attribute, "position");
        glBindAttribLocation(program, vert_texture_attribute, "texture_coord");
        glBindAttribLocation(program, vert_normal_attribute, "normal");
        //glBindFragDataLocation(program, 0, "gl_FragColor");

        glLinkProgram(program);

        //texture_attrib = glGetUniformLocation(program, "tex");
        projection_transform_attrib = glGetUniformLocation(program, "projection_transform");
        view_transform_attrib = glGetUniformLocation(program, "view_transform");
        model_transform_attrib = glGetUniformLocation(program, "model_transform");
        un_projection_transform_attrib = glGetUniformLocation(program, "un_projection_transform");
        un_view_transform_attrib = glGetUniformLocation(program, "un_view_transform");
        un_model_transform_attrib = glGetUniformLocation(program, "un_model_transform");
        light_count_attrib = glGetUniformLocation(program, "light_count");

        use_texture_attrib = glGetUniformLocation(program, "use_texture");
        ambient_color_attrib = glGetUniformLocation(program, "ambient_color");
        diffuse_color_attrib = glGetUniformLocation(program, "diffuse_color");
        specular_color_attrib = glGetUniformLocation(program, "specular_color");
        ambient_material_attrib = glGetUniformLocation(program, "ambient_material_multiplier");
        diffuse_material_attrib = glGetUniformLocation(program, "diffuse_material_multiplier");
        specular_material_attrib = glGetUniformLocation(program, "specular_material_multiplier");

        specular_exponent_attrib = glGetUniformLocation(program, "specular_exponent");
        alpha_attrib = glGetUniformLocation(program, "alpha");

        for (int i = 0; i < lights.length; i++)
            lights[i].init(program);

        uint err = glGetError();
        if (err != 0 && err != 0x500)
        {
            EngineLog.log(EngineLogType.RENDERING, "OpenGLShaderProgram3D", "GL shader program linkage failure (" + err.to_string() + ")");
            return false;
        }

        return true;
    }

    public void use_program()
    {
        glUseProgram(program);
    }

    public void apply_scene(Transform projection_transform, Transform view_transform, ArrayList<LightSource> lights)
    {
        use_program();

        Mat4 proj_mat = projection_transform.matrix;
        Mat4 view_mat = view_transform.matrix;

        glUniformMatrix4fv(projection_transform_attrib, 1, false, proj_mat.get_data());
        glUniformMatrix4fv(view_transform_attrib, 1, false, view_mat.get_data());
        glUniformMatrix4fv(un_projection_transform_attrib, 1, false, proj_mat.inverse().get_data());
        glUniformMatrix4fv(un_view_transform_attrib, 1, false, view_mat.inverse().get_data());
        glUniform1i(light_count_attrib, lights.size);

        for (int i = 0; i < lights.size; i++)
            this.lights[i].apply(lights[i].position, lights[i].color, lights[i].intensity);
    }

    public void render_object(int triangle_count, Transform model_transform, RenderMaterial material, bool use_texture)
    {
        Mat4 mat = model_transform.matrix;

        glUniformMatrix4fv(model_transform_attrib, 1, false, mat.get_data());
        glUniformMatrix4fv(un_model_transform_attrib, 1, false, mat.inverse().get_data());

        glUniform1i(use_texture_attrib, (int)use_texture);
        glUniform4f(ambient_color_attrib, material.ambient_color.r, material.ambient_color.g, material.ambient_color.b, material.ambient_color.a);
        glUniform4f(diffuse_color_attrib, material.diffuse_color.r, material.diffuse_color.g, material.diffuse_color.b, material.diffuse_color.a);
        glUniform4f(specular_color_attrib, material.specular_color.r, material.specular_color.g, material.specular_color.b, material.specular_color.a);
        glUniform1f(ambient_material_attrib, material.ambient_material_strength);
        glUniform1f(diffuse_material_attrib, material.diffuse_material_strength);
        glUniform1f(specular_material_attrib, material.specular_material_strength);

        glUniform1f(specular_exponent_attrib, material.specular_exponent);
        glUniform1f(alpha_attrib, material.alpha);

        glDrawArrays(GL_TRIANGLES, 0, triangle_count);
    }
}

private class OpenGLLightSource
{
    private int position_attrib;
    private int color_attrib;
    private int intensity_attrib;

    public OpenGLLightSource(int index)
    {
        this.index = index;
    }

    public void init(uint program)
    {
        position_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].position");
        color_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].color");
        intensity_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].intensity");
    }

    public void apply(Transform transform, Color color, float intensity)
    {
        Vec3 position = transform.position;
        glUniform3f(position_attrib, position.x, position.y, position.z);
        glUniform3f(color_attrib, color.r, color.g, color.b);
        glUniform1f(intensity_attrib, intensity);
    }

    public int index { get; private set; }
}
