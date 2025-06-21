$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "scheme"="https"
  "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "cache-control"="max-age=0"
  "dnt"="1"
  "if-modified-since"="Fri, 20 Jun 2025 16:31:07 GMT"
  "if-none-match"="`"a2dbb069aae3b9edae763ca0d9c826cd`""
  "priority"="u=0, i"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="document"
  "sec-fetch-mode"="navigate"
  "sec-fetch-site"="same-origin"
  "sec-fetch-user"="?1"
  "sec-gpc"="1"
  "upgrade-insecure-requests"="1"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/issues-DYW_fZUY.js" `
-WebSession $session `
-Headers @{
"Origin"="https://sonarcloud.io"
  "sec-ch-ua-platform"="`"Android`""
  "Referer"=""
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "DNT"="1"
  "sec-ch-ua-mobile"="?1"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&facets=cleanCodeAttributeCategories%2CimpactSoftwareQualities%2CimpactSeverities&componentKeys=w159_unstract&organization=w159&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&facets=cleanCodeAttributeCategories%2CimpactSoftwareQualities%2CimpactSeverities&componentKeys=w159_unstract&organization=w159&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=2&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=2&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=3&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=3&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=4&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=4&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))
Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=5&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=5&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
};
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36 Edg/137.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_mid", "df18cc72-7d2c-4482-8832-07b88c9ac8b9ed162b", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_USER_ID_brLvVEua59285", "73dcb132-7f00-4afb-afec-3a8e6dd20751", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FIRST_VISIT_brLvVEua59285", "2025-06-21T03:04:06.702Z", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("_BEAMER_FILTER_BY_URL_brLvVEua59285", "false", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("__stripe_sid", "55133424-6166-4bb9-a0fd-ac1c4ff92877d50045", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("XSRF-TOKEN", "guej7f9q13f6ra54of84q6f9ve", "/", ".sonarcloud.io")))
$session.Cookies.Add((New-Object System.Net.Cookie("JWT-SESSION", "eyJhbGciOiJIUzI1NiJ9.eyJsYXN0UmVmcmVzaFRpbWUiOjE3NTA0ODM1ODAwMTUsInhzcmZUb2tlbiI6Imd1ZWo3ZjlxMTNmNnJhNTRvZjg0cTZmOXZlIiwianRpIjoiQVplUTY1Qm9kcGNZMUdSNTVQRlkiLCJzdWIiOiJBWmVRY1hYNmRwY1kxR1I1NU9qUiIsImlhdCI6MTc1MDQ4MzA0NiwiZXhwIjoxNzUwNTY5OTgwfQ.UORRtdCrVAGV5y7BZRIRZIiTZG5azXKKvnGaEWaaIRk", "/", ".sonarcloud.io")))


$request = Invoke-WebRequest -UseBasicParsing -Uri "https://sonarcloud.io/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=6&additionalFields=_all" `
-WebSession $session `
-Headers @{
"authority"="sonarcloud.io"
  "method"="GET"
  "path"="/api/issues/search?s=FILE_LINE&issueStatuses=OPEN%2CCONFIRMED&ps=100&componentKeys=w159_unstract&organization=w159&p=6&additionalFields=_all"
  "scheme"="https"
  "accept"="application/json"
  "accept-encoding"="gzip, deflate, br, zstd"
  "accept-language"="en-US,en;q=0.9,de-CH;q=0.8,de;q=0.7"
  "dnt"="1"
  "priority"="u=1, i"
  "referer"="https://sonarcloud.io/project/issues?issueStatuses=OPEN%2CCONFIRMED&id=w159_unstract"
  "sec-ch-ua"="`"Microsoft Edge`";v=`"137`", `"Chromium`";v=`"137`", `"Not/A)Brand`";v=`"24`""
  "sec-ch-ua-mobile"="?1"
  "sec-ch-ua-platform"="`"Android`""
  "sec-fetch-dest"="empty"
  "sec-fetch-mode"="cors"
  "sec-fetch-site"="same-origin"
  "sec-gpc"="1"
  "x-xsrf-token"="guej7f9q13f6ra54of84q6f9ve"
}



$issues = ($request.Content | ConvertFrom-Json).issues

# Convert the issues to a custom object for easier handling
$issues = $issues | ForEach-Object {
    [PSCustomObject]@{
        key = $_.key
        rule = $_.rule
        severity = $_.severity
        component = $_.component
        project = $_.project
        status = $_.status
        message = $_.message
        line = $_.line
        textRange = $_.textRange
    }
}

# Create a custom object for each issue with the desired properties
$issues | ForEach-Object {
    $issue = $_
    [PSCustomObject]@{
        Key = $issue.key
        Rule = $issue.rule
        Severity = $issue.severity
        Component = $issue.component
        Project = $issue.project
        Status = $issue.status
        Message = $issue.message
        Line = $issue.line
        TextRange = $issue.textRange
        # Generate URL for the issue, since the object isn't in the array
        # URL is generated by creating a new column and appending the issue key from the issue object
        URL = "https://sonarcloud.io/project/issues?id=w159_unstract&open=" + $issue.key
    }
}
# Output the issues in a table format
# Note: The URL below is the link to the SonarCloud project issues page for the specified project.
# You can click on it to view the issues directly in your browser.
# Link to the SonarCloud project issues page


$issues | select Severity, Component, TextRange, URL

$issues | export-csv -Path "curl_issues_test.csv" -NoTypeInformation
