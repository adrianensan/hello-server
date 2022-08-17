let htmlPage403: String = """
<!DOCTYPE html>
<html>
<head>
<title>Access Denied</title>
<style>
* {
margin: 0;
}

body {
background: #151515;
}

p {
font-family: "Lucida Console", Monaco, monospace;
text-align: center;
}

#error {
margin-top: 50vh;
transform: translateY(-50%);
}

#error_code {
color: #991111;
alignment-baseline: middle;
font-size: 100px;

}

#page_not_found {
color: #999999;
font-size: 24px;
}
</style>
</head>
<body>
<div id="error">
<p id="error_code">403</p>
<p id="page_not_found">Access Denied</p>
</div>
</body>
</html>
"""
