uniform float rectangle[4]; // 矩形数组 [x, y, width, height]
uniform float tanAngle;
uniform float judge; // 透视参考点的Y坐标（相对于矩形中心的比例，范围-1到1）

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    
    // 获取矩形参数
    float x_start = rectangle[0];
    float y_start = rectangle[1];
    float width = rectangle[2];
    float height = rectangle[3];
    
    // 转换为相对于矩形中心的坐标
    float centerX = x_start + width / 2.0;
    float centerY = y_start + height / 2.0;
    
    float relX = vertex_position.x - centerX;
    float relY = vertex_position.y - centerY;
    
    // 计算在judge位置处的透视因子应该为1
    // judge的取值范围：-1（底部）到1（顶部），0表示中心
    // 公式：perspFactor = 1.0 + (relY - judgeY) * k
    // 其中judgeY = judge * (height / 2.0)
    float judgeY = judge * (height / 2.0);
    float perspStrength = 1.0 / tanAngle; // 透视强度
    
    // 修正后的透视因子，使得在judgeY处perspFactor = 1
    float perspFactor = 1.0 + (relY - judgeY) * (perspStrength / (height / 2.0));
    perspFactor = max(0.1, perspFactor);  // 防止过度拉伸
    
    // 应用透视
    float x3d = relX / perspFactor;
    float y3d = relY;  // Y坐标保持不变
    
    // 转换回屏幕坐标
    float screenX = centerX + x3d;
    float screenY = centerY + y3d;
    
    return transform_projection * vec4(screenX, screenY, 0.0, 1.0);
}