public class Mat4
{
    private Vec4 v1;
    private Vec4 v2;
    private Vec4 v3;
    private Vec4 v4;

    public Mat4()
    {
        with_vecs
        (
            Vec4(1, 0, 0, 0),
            Vec4(0, 1, 0, 0),
            Vec4(0, 0, 1, 0),
            Vec4(0, 0, 0, 1)
        );
    }

    public Mat4.with_array(float *a)
    {
        v1 = Vec4(a[ 0], a[ 1], a[ 2], a[ 3]);
        v2 = Vec4(a[ 4], a[ 5], a[ 6], a[ 7]);
        v3 = Vec4(a[ 8], a[ 9], a[10], a[11]);
        v4 = Vec4(a[12], a[13], a[14], a[15]);
    }

    public Mat4.with_vecs(Vec4 v1, Vec4 v2, Vec4 v3, Vec4 v4)
    {
        this.v1 = v1;
        this.v2 = v2;
        this.v3 = v3;
        this.v4 = v4;
    }

    public Mat4? inverse()
    {
        float mat[16], inv[16];

        Vec4 *v = (Vec4*)mat;
        v[0] = v1;
        v[1] = v2;
        v[2] = v3;
        v[3] = v4;

        return gluInvertMatrix(mat, inv) ? new Mat4.with_array(inv) : null;
    }

    public Mat4 transpose()
    {
        Vec4 v1 = this.col(0);
        Vec4 v2 = this.col(1);
        Vec4 v3 = this.col(2);
        Vec4 v4 = this.col(3);

        return new Mat4.with_vecs(v1, v2, v3, v4);
    }

    public Mat4 copy()
    {
        Vec4 v1 = this.v1;
        Vec4 v2 = this.v2;
        Vec4 v3 = this.v3;
        Vec4 v4 = this.v4;

        return new Mat4.with_vecs(v1, v2, v3, v4);
    }

    // this*mat
    public Mat4 mul_mat(Mat4 mat)
    {
        Vec4 vec1 =
        {
            v1.dot(mat.col(0)),
            v1.dot(mat.col(1)),
            v1.dot(mat.col(2)),
            v1.dot(mat.col(3))
        };

        Vec4 vec2 =
        {
            v2.dot(mat.col(0)),
            v2.dot(mat.col(1)),
            v2.dot(mat.col(2)),
            v2.dot(mat.col(3))
        };

        Vec4 vec3 =
        {
            v3.dot(mat.col(0)),
            v3.dot(mat.col(1)),
            v3.dot(mat.col(2)),
            v3.dot(mat.col(3))
        };

        Vec4 vec4 =
        {
            v4.dot(mat.col(0)),
            v4.dot(mat.col(1)),
            v4.dot(mat.col(2)),
            v4.dot(mat.col(3))
        };

        return new Mat4.with_vecs(vec1, vec2, vec3, vec4);
    }

    public Vec4 mul_vec(Vec4 vec)
    {
        return
        {
            v1.dot(vec),
            v2.dot(vec),
            v3.dot(vec),
            v4.dot(vec)
        };
    }

    public Vec4 col(int c)
    {
        return
        {
            ((float*)(&v1))[c],
            ((float*)(&v2))[c],
            ((float*)(&v3))[c],
            ((float*)(&v4))[c]
        };
    }

    public float[] get_data()
    {
        float[] mat = new float[16];
        Vec4 *v = (Vec4*)mat;
        v[0] = v1;
        v[1] = v2;
        v[2] = v3;
        v[3] = v4;

        return mat;
    }

    public float get(int i)
    {
        Vec4 v = {};
        int a = i / 4;
             if (a == 0) v = v1;
        else if (a == 1) v = v2;
        else if (a == 2) v = v3;
        else if (a == 3) v = v4;
        return v[i % 4];
    }

    // From Mesa 3D Graphics Library
    private static bool gluInvertMatrix(float *m, float *invOut)
    {
        float inv[16], det;
        int i;

        inv[0] = m[5]  * m[10] * m[15] -
                 m[5]  * m[11] * m[14] -
                 m[9]  * m[6]  * m[15] +
                 m[9]  * m[7]  * m[14] +
                 m[13] * m[6]  * m[11] -
                 m[13] * m[7]  * m[10];

        inv[4] = -m[4]  * m[10] * m[15] +
                  m[4]  * m[11] * m[14] +
                  m[8]  * m[6]  * m[15] -
                  m[8]  * m[7]  * m[14] -
                  m[12] * m[6]  * m[11] +
                  m[12] * m[7]  * m[10];

        inv[8] = m[4]  * m[9] * m[15] -
                 m[4]  * m[11] * m[13] -
                 m[8]  * m[5] * m[15] +
                 m[8]  * m[7] * m[13] +
                 m[12] * m[5] * m[11] -
                 m[12] * m[7] * m[9];

        inv[12] = -m[4]  * m[9] * m[14] +
                   m[4]  * m[10] * m[13] +
                   m[8]  * m[5] * m[14] -
                   m[8]  * m[6] * m[13] -
                   m[12] * m[5] * m[10] +
                   m[12] * m[6] * m[9];

        inv[1] = -m[1]  * m[10] * m[15] +
                  m[1]  * m[11] * m[14] +
                  m[9]  * m[2] * m[15] -
                  m[9]  * m[3] * m[14] -
                  m[13] * m[2] * m[11] +
                  m[13] * m[3] * m[10];

        inv[5] = m[0]  * m[10] * m[15] -
                 m[0]  * m[11] * m[14] -
                 m[8]  * m[2] * m[15] +
                 m[8]  * m[3] * m[14] +
                 m[12] * m[2] * m[11] -
                 m[12] * m[3] * m[10];

        inv[9] = -m[0]  * m[9] * m[15] +
                  m[0]  * m[11] * m[13] +
                  m[8]  * m[1] * m[15] -
                  m[8]  * m[3] * m[13] -
                  m[12] * m[1] * m[11] +
                  m[12] * m[3] * m[9];

        inv[13] = m[0]  * m[9] * m[14] -
                  m[0]  * m[10] * m[13] -
                  m[8]  * m[1] * m[14] +
                  m[8]  * m[2] * m[13] +
                  m[12] * m[1] * m[10] -
                  m[12] * m[2] * m[9];

        inv[2] = m[1]  * m[6] * m[15] -
                 m[1]  * m[7] * m[14] -
                 m[5]  * m[2] * m[15] +
                 m[5]  * m[3] * m[14] +
                 m[13] * m[2] * m[7] -
                 m[13] * m[3] * m[6];

        inv[6] = -m[0]  * m[6] * m[15] +
                  m[0]  * m[7] * m[14] +
                  m[4]  * m[2] * m[15] -
                  m[4]  * m[3] * m[14] -
                  m[12] * m[2] * m[7] +
                  m[12] * m[3] * m[6];

        inv[10] = m[0]  * m[5] * m[15] -
                  m[0]  * m[7] * m[13] -
                  m[4]  * m[1] * m[15] +
                  m[4]  * m[3] * m[13] +
                  m[12] * m[1] * m[7] -
                  m[12] * m[3] * m[5];

        inv[14] = -m[0]  * m[5] * m[14] +
                   m[0]  * m[6] * m[13] +
                   m[4]  * m[1] * m[14] -
                   m[4]  * m[2] * m[13] -
                   m[12] * m[1] * m[6] +
                   m[12] * m[2] * m[5];

        inv[3] = -m[1] * m[6] * m[11] +
                  m[1] * m[7] * m[10] +
                  m[5] * m[2] * m[11] -
                  m[5] * m[3] * m[10] -
                  m[9] * m[2] * m[7] +
                  m[9] * m[3] * m[6];

        inv[7] = m[0] * m[6] * m[11] -
                 m[0] * m[7] * m[10] -
                 m[4] * m[2] * m[11] +
                 m[4] * m[3] * m[10] +
                 m[8] * m[2] * m[7] -
                 m[8] * m[3] * m[6];

        inv[11] = -m[0] * m[5] * m[11] +
                   m[0] * m[7] * m[9] +
                   m[4] * m[1] * m[11] -
                   m[4] * m[3] * m[9] -
                   m[8] * m[1] * m[7] +
                   m[8] * m[3] * m[5];

        inv[15] = m[0] * m[5] * m[10] -
                  m[0] * m[6] * m[9] -
                  m[4] * m[1] * m[10] +
                  m[4] * m[2] * m[9] +
                  m[8] * m[1] * m[6] -
                  m[8] * m[2] * m[5];

        det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

        if (det == 0)
            return false;

        det = 1 / det;

        for (i = 0; i < 16; i++)
            invOut[i] = inv[i] * det;

        return true;
    }
}
