<?php
header('Content-type:text/html;charset=utf-8');

// 从环境变量读取数据库连接信息
$db_host = getenv('DB_HOST');
$db_name = getenv('DB_NAME');
$db_user = getenv('DB_USER');
$db_pass = getenv('DB_PASSWORD');

$arr = $_POST;

$conn = mysqli_connect($db_host, $db_user, $db_pass);
if (!$conn) {
    die("数据库连接失败");
}
mysqli_select_db($conn, $db_name);
mysqli_query($conn, "set names utf8mb4");

$qqurl = "https://api.vvhan.com/api/qt?qq=";
if ($arr['userqq'] != '')
    $qqurl .= $arr['userqq'];
else
    $qqurl .= '1';

function avoidhit($str) {
    $str = addslashes($str);  // 防止SQL注入（配合转义）
    return $str;
}

if (avoidhit($arr['username']) == '' || avoidhit($arr['msg']) == '') {
    echo "<script>alert('请填写完整的信息');location.href='message.php';</script>";
} else {
    $sql = "insert into obj_message set name='" . avoidhit($arr['username']) . "', head_image='" . avoidhit($qqurl) . "', word='" . avoidhit($arr['msg']) . "', time='" . date("Y-m-d H-i-s") . "', site='" . avoidhit($arr['usersite']) . "', email='" . avoidhit($arr['email']) . "'";
    $rst = mysqli_query($conn, $sql);
    if ($rst) {
        echo "<script>alert('留言成功');location.href='message.php';</script>";
    } else {
        echo "<script>alert('留言失败');location.href='message.php';</script>";
    }
}
?>