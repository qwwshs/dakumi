uniform float rectangle[4]; // 矩形数组 [x, y, width, height]
uniform float tanAngle;
uniform float judge; // 判定线在矩形内的位置比例 (0~1, 0=顶部, 1=底部)

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // 获取矩形参数
    float x_start = rectangle[0];
    float y_start = rectangle[1];
    float width = rectangle[2];
    float height = rectangle[3];
    
    // 转换为矩形内的归一化坐标 (0~1)
    float relX = (vertex_position.x - x_start) / width;
    float relY = (vertex_position.y - y_start) / height;
    
    // 透视强度
    float perspStrength = max(tanAngle, 0.0000000001);
    
    // 透视因子：判定线(relY=judge)处为1，越往下(relY>judge)收缩，越往上(relY<judge)放大
    // 上下斜率一致，限制范围关于1.0对称
    float perspFactor = 1.0 + (judge - relY) * perspStrength;
    
    // 对称限制，上限和下限互为倒数
    float maxFactor = 1.0 + perspStrength * 0.5;
    float minFactor = 1.0 / maxFactor;
    perspFactor = clamp(perspFactor, minFactor, maxFactor);
    
    // 应用透视：x 以矩形中心为基准缩放
    float x3d = (relX - 0.5) / perspFactor + 0.5;
    
    // 转换回屏幕坐标
    float screenX = x_start + x3d * width;
    float screenY = vertex_position.y;
    
    return transform_projection * vec4(screenX, screenY, 0.0, 1.0);
}