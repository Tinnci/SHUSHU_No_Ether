#!/bin/bash

LOG_DIR="/opt/log"
USER_AGENT="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"

# ȷ����־Ŀ¼����
mkdir -p "$LOG_DIR"

# ��¼��־�ĺ���
log() {
    local LOG_TYPE=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
    local LOG_FILE="$LOG_DIR/general_$LOG_TYPE_$TIMESTAMP.log"
    
    echo -e "[$LOG_TYPE] $TIMESTAMP: $MESSAGE" >> "$LOG_FILE"
    echo -e "[$LOG_TYPE] $TIMESTAMP: $MESSAGE"
}

# ��¼������־
log_error() {
    log "ERROR" "$1"
}

# ��¼��ͨ��Ϣ��־
log_info() {
    log "INFO" "$1"
}

# ͨ�õĳ�ʱ������
timeout_handler() {
    log_error "Operation timed out after 15 seconds, please check your network connection."
    exit 1
}

# ʹ�� nc �� ping/curl ���������ϸ״̬
# �����õļ�����ɵ����ĺ�������������
check_network_connectivity() {
    # ���˿��Ƿ񿪷�
    if nc -zw3 10.10.9.9 8080; then
        log_info "nc: Port is open."
    else
        log_error "nc: Port is closed or host is unreachable."
        return 1
    fi

    # ����Ƿ��ܹ� ping ͨ
    if ping -c 1 10.10.9.9 &>/dev/null; then
        log_info "Ping successful."
    else
        log_error "Ping check failed - Network is down."
        return 2
    fi
}

# ������¼���ݵĺ���
construct_login_data() {
    log_info "Constructing login data..."
    local curl_result
    curl_result=$(timeout 15 curl -s "http://123.123.123.123/" || timeout_handler)
    local QUERY_STRING=$(echo "$curl_result" | awk -F "index.jsp?" '/index.jsp?/{print $2}' | awk -F "'</script>" '{print $1}')
    local DATA="userId=${USER_ID}&password=${USER_PASSWORD}&passwordEncrypt=false&queryString=${QUERY_STRING}&service=shu&operatorPwd=&operatorUserId=&validcode="
    echo "$DATA"
}

# ��¼����
login() {
    local LOGIN_DATA RESPONSE RESULT MESSAGE
    log_info "Attempting to login..."
    LOGIN_DATA=$(construct_login_data)
    RESPONSE=$(timeout 15 curl -s -d "$LOGIN_DATA" -H "$USER_AGENT" -X POST "http://10.10.9.9:8080/eportal/InterFace.do?method=login" || timeout_handler)
    RESULT=$(echo "$RESPONSE" | grep -o -E '"result":"[^"]+"' | cut -d '"' -f 4)
    MESSAGE=$(echo "$RESPONSE" | grep -o -E '"message":"[^"]+"' | cut -d '"' -f 4)
    if [ "$RESULT" == "success" ]; then
        log_info "Authentication successful, User ${USER_ID} logged in."
    else
        log_error "Authentication failed: $MESSAGE."
        return 3
    fi
}

# ִ�����߼�
main() {
    if [ -z "$USER_ID" ] || [ -z "$USER_PASSWORD" ]; then
        log_error "Missing credentials."
        echo "Usage: $0 -a <account> -p <password>"
        exit 1
    fi

    # �洢״̬
    local status
    check_network_connectivity
    status=$?

    # ���ݼ������ȡ�ж�
    case $status in
    0) log_info "Network status is good. Checking authentication status next...";;
    1|2) log_error "Network is down or port is closed.";;
    esac

    # ֻ�е���������ʱ��ȥ���Ե�¼
    if [ $status -eq 0 ]; then
        login
        status=$?
        if [ $status -eq 3 ]; then
            log_error "Failed to login, possibly due to incorrect credentials or service issues."
        fi
    fi
}

# ���������в���
while getopts "a:p:" opt; do
  case $opt in
    a) USER_ID=$OPTARG ;;
    p) USER_PASSWORD=$OPTARG ;;
    \?)
        log_error "Invalid option: -$OPTARG requires an argument."
        echo "Usage: $0 -a <account> -p <password>" >&2
        exit 1
      ;;
  esac
done

# ȷ����Ҫ�����Ѿ�����
if [ -z "$USER_ID" ] || [ -z "$USER_PASSWORD" ]; then
    echo "Usage: $0 -a <account> -p <password>" >&2
    exit 1
fi

# �������߼�
main