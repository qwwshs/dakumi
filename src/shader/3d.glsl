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
    float perspStrength = max(tanAngle, 0.001);
    
    // 透视因子：判定线(relY=judge)处为1，越往下(relY>judge)收缩，越往上(relY<judge)放大
    float perspFactor = 1.0 + (judge - relY) * perspStrength;
    
    // 限制透视范围
    perspFactor = max(0.3, min(perspFactor, 10.0));
    
    // 应用透视：x 以矩形中心为基准缩放
    // 同时 y 也根据透视因子调整，保持像素点之间的相对位置正确
    float x3d = (relX - 0.5) / perspFactor + 0.5;
    
    // 转换回屏幕坐标
    float screenX = x_start + x3d * width;
    float screenY = vertex_position.y;
    
    return transform_projection * vec4(screenX, screenY, 0.0, 1.0);
}