#!/usr/bin/env bash

set +e
set -o errexit
set -o nounset
set -o pipefail

# ============================================================================
# Default Configuration
# ============================================================================
DEFAULT_CLUSTER_NAME="my-pg"
DEFAULT_ENGINE="postgresql"
DEFAULT_VERSION="18.1.0"
DEFAULT_MODE="replication"
DEFAULT_ENVIRONMENT="prod"
DEFAULT_REPLICAS=2
DEFAULT_STORAGE_SIZE=20
DEFAULT_CLASS_CODE="postgresql.replication.postgresql.1c2g.general"
DEFAULT_READ_IOPS=2000
DEFAULT_WRITE_IOPS=2000
DEFAULT_TERMINATION_POLICY="Delete"

# ============================================================================
# Help Message
# ============================================================================
show_help() {
cat << EOF
Usage: $(basename "$0") <options>

KubeBlocks PostgreSQL Cluster Terraform Test Script

Options:
    -h, --help                              Display help message
    
    -t, --type                              Operation type
                                              1) init & apply (create cluster)
                                              2) destroy (delete cluster)
                                              3) plan (preview changes)
                                              4) vscale (vertical scaling)
                                              5) hscale (horizontal scaling)
                                              6) reconfigure (modify parameters)
                                              7) backup (configure backup)
                                              8) termination (change policy)
    
    -cn, --cluster-name                     Cluster name (default: $DEFAULT_CLUSTER_NAME)
    -e, --engine                            Database engine (default: $DEFAULT_ENGINE)
    -v, --version                           Engine version (default: $DEFAULT_VERSION)
    -m, --mode                              Deployment mode (default: $DEFAULT_MODE)
    -env, --environment                     Environment name (default: $DEFAULT_ENVIRONMENT)
    
    -r, --replicas                          Number of replicas (default: $DEFAULT_REPLICAS)
    -s, --storage-size                      Storage size in GB (default: $DEFAULT_STORAGE_SIZE)
    -cc, --class-code                       Instance class code (default: $DEFAULT_CLASS_CODE)
    -ri, --read-iops                        Read IOPS limit (default: $DEFAULT_READ_IOPS)
    -wi, --write-iops                       Write IOPS limit (default: $DEFAULT_WRITE_IOPS)
    
    -tp, --termination-policy               Termination policy (Delete/DoNotTerminate)
    
    -ab, --auto-backup                      Enable auto backup (true/false)
    -bm, --backup-method                    Backup method (xtrabackup)
    -bs, --backup-schedule                  Backup schedule (cron expression)
    -rp, --retention-policy                 Retention policy (LastOne/7d/etc)
    
    -cp, --custom-params                    Custom parameters (JSON format)
    -ptn, --param-template                  Parameter template name
    
    -api-url                                API URL
    -api-key                                API key
    -api-secret                             API secret
    -admin-api-key                          Admin API key
    -admin-api-secret                       Admin API secret

Examples:
    # Create a default MySQL cluster
    ./run.sh -t 1
    
    # Create cluster with custom configuration
    ./run.sh -t 1 \\
        -cn "mysql-prod" \\
        -env "prod" \\
        -r 3 \\
        -s 100 \\
        -cc "mysql.replication.mysql.4c8g.performance"
    
    # Scale up compute resources
    ./run.sh -t 4 \\
        -cc "mysql.replication.mysql.2c4g.general"
    
    # Scale out replicas
    ./run.sh -t 5 \\
        -r 5
    
    # Enable automatic backup
    ./run.sh -t 7 \\
        -ab true \\
        -bm "xtrabackup" \\
        -bs "0 2 * * *"
    
    # Destroy cluster
    ./run.sh -t 2

EOF
}

# ============================================================================
# Initialize and Apply
# ============================================================================
terraform_init_and_apply() {
    echo "=========================================="
    echo "Initializing Terraform..."
    echo "=========================================="
    terraform init

    echo ""
    echo "=========================================="
    echo "Creating terraform.tfvars..."
    echo "=========================================="
    
    # Copy example template
    cp terraform.tfvars.example terraform.tfvars
    
    # Update values using sed (macOS and Linux compatible)
    if [[ "$UNAME" == "Darwin" ]]; then
        # macOS
        [[ -n "$CLUSTER_NAME" ]] && sed -i '' "s/^cluster_name.*/cluster_name = \"$CLUSTER_NAME\"/" terraform.tfvars
        [[ -n "$ENGINE" ]] && sed -i '' "s/^engine.*/engine = \"$ENGINE\"/" terraform.tfvars
        [[ -n "$VERSION" ]] && sed -i '' "s/^version.*/version = \"$VERSION\"/" terraform.tfvars
        [[ -n "$MODE" ]] && sed -i '' "s/^mode.*/mode = \"$MODE\"/" terraform.tfvars
        [[ -n "$ENVIRONMENT" ]] && sed -i '' "s/^environment_name.*/environment_name = \"$ENVIRONMENT\"/" terraform.tfvars
        [[ -n "$REPLICAS" ]] && sed -i '' "s/^replicas.*/replicas = $REPLICAS/" terraform.tfvars
        [[ -n "$STORAGE_SIZE" ]] && sed -i '' "s/^storage_size_gb.*/storage_size_gb = $STORAGE_SIZE/" terraform.tfvars
        [[ -n "$CLASS_CODE" ]] && sed -i '' "s/^class_code.*/class_code = \"$CLASS_CODE\"/" terraform.tfvars
        [[ -n "$READ_IOPS" ]] && sed -i '' "s/^read_iops.*/read_iops = $READ_IOPS/" terraform.tfvars
        [[ -n "$WRITE_IOPS" ]] && sed -i '' "s/^write_iops.*/write_iops = $WRITE_IOPS/" terraform.tfvars
        [[ -n "$TERMINATION_POLICY" ]] && sed -i '' "s/^termination_policy.*/termination_policy = \"$TERMINATION_POLICY\"/" terraform.tfvars
        
        # API credentials (if provided)
        [[ -n "$API_KEY" ]] && sed -i '' "s/^# api_key.*/api_key = \"$API_KEY\"/" terraform.tfvars
        [[ -n "$API_SECRET" ]] && sed -i '' "s/^# api_secret.*/api_secret = \"$API_SECRET\"/" terraform.tfvars
        [[ -n "$ADMIN_API_KEY" ]] && sed -i '' "s/^# admin_api_key.*/admin_api_key = \"$ADMIN_API_KEY\"/" terraform.tfvars
        [[ -n "$ADMIN_API_SECRET" ]] && sed -i '' "s/^# admin_api_secret.*/admin_api_secret = \"$ADMIN_API_SECRET\"/" terraform.tfvars
    else
        # Linux
        [[ -n "$CLUSTER_NAME" ]] && sed -i "s/^cluster_name.*/cluster_name = \"$CLUSTER_NAME\"/" terraform.tfvars
        [[ -n "$ENGINE" ]] && sed -i "s/^engine.*/engine = \"$ENGINE\"/" terraform.tfvars
        [[ -n "$VERSION" ]] && sed -i "s/^version.*/version = \"$VERSION\"/" terraform.tfvars
        [[ -n "$MODE" ]] && sed -i "s/^mode.*/mode = \"$MODE\"/" terraform.tfvars
        [[ -n "$ENVIRONMENT" ]] && sed -i "s/^environment_name.*/environment_name = \"$ENVIRONMENT\"/" terraform.tfvars
        [[ -n "$REPLICAS" ]] && sed -i "s/^replicas.*/replicas = $REPLICAS/" terraform.tfvars
        [[ -n "$STORAGE_SIZE" ]] && sed -i "s/^storage_size_gb.*/storage_size_gb = $STORAGE_SIZE/" terraform.tfvars
        [[ -n "$CLASS_CODE" ]] && sed -i "s/^class_code.*/class_code = \"$CLASS_CODE\"/" terraform.tfvars
        [[ -n "$READ_IOPS" ]] && sed -i "s/^read_iops.*/read_iops = $READ_IOPS/" terraform.tfvars
        [[ -n "$WRITE_IOPS" ]] && sed -i "s/^write_iops.*/write_iops = $WRITE_IOPS/" terraform.tfvars
        [[ -n "$TERMINATION_POLICY" ]] && sed -i "s/^termination_policy.*/termination_policy = \"$TERMINATION_POLICY\"/" terraform.tfvars
        
        # API credentials (if provided)
        [[ -n "$API_KEY" ]] && sed -i "s/^# api_key.*/api_key = \"$API_KEY\"/" terraform.tfvars
        [[ -n "$API_SECRET" ]] && sed -i "s/^# api_secret.*/api_secret = \"$API_SECRET\"/" terraform.tfvars
        [[ -n "$ADMIN_API_KEY" ]] && sed -i "s/^# admin_api_key.*/admin_api_key = \"$ADMIN_API_KEY\"/" terraform.tfvars
        [[ -n "$ADMIN_API_SECRET" ]] && sed -i "s/^# admin_api_secret.*/admin_api_secret = \"$ADMIN_API_SECRET\"/" terraform.tfvars
    fi
    
    echo ""
    echo "=========================================="
    echo "Configuration Summary:"
    echo "=========================================="
    echo "Cluster Name:      $CLUSTER_NAME"
    echo "Engine:            $ENGINE"
    echo "Version:           $VERSION"
    echo "Mode:              $MODE"
    echo "Environment:       $ENVIRONMENT"
    echo "Replicas:          $REPLICAS"
    echo "Storage Size:      ${STORAGE_SIZE} GB"
    echo "Class Code:        $CLASS_CODE"
    echo "Termination Policy: $TERMINATION_POLICY"
    echo "IOPS (Read/Write): ${READ_IOPS}/${WRITE_IOPS}"
    echo "=========================================="
    echo ""
    
    echo "Running: terraform plan -out mysql_plan"
    terraform plan -out=mysql_plan -var-file=terraform.tfvars
    
    echo ""
    echo "Running: terraform apply mysql_plan"
    terraform apply mysql_plan
    
    echo ""
    echo "=========================================="
    echo "Cluster creation completed!"
    echo "=========================================="
}

# ============================================================================
# Destroy
# ============================================================================
terraform_destroy() {
    echo "=========================================="
    echo "Initializing Terraform..."
    echo "=========================================="
    terraform init
    
    echo ""
    echo "=========================================="
    echo "WARNING: This will destroy the cluster!"
    echo "=========================================="
    echo "Cluster Name: $CLUSTER_NAME"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
    
    echo ""
    echo "Running: terraform destroy -auto-approve"
    terraform destroy -auto-approve -var-file=terraform.tfvars
    
    echo ""
    echo "=========================================="
    echo "Cluster destroyed!"
    echo "=========================================="
}

# ============================================================================
# Plan
# ============================================================================
terraform_plan() {
    echo "=========================================="
    echo "Initializing Terraform..."
    echo "=========================================="
    terraform init
    
    echo ""
    echo "=========================================="
    echo "Running: terraform plan"
    echo "=========================================="
    terraform plan -var-file=terraform.tfvars
}

# ============================================================================
# VScale (Vertical Scaling)
# ============================================================================
terraform_vscale() {
    echo "=========================================="
    echo "Performing Vertical Scaling..."
    echo "=========================================="
    
    if [[ ! -f "terraform.tfvars" ]]; then
        echo "Error: terraform.tfvars not found. Please create cluster first (-t 1)"
        exit 1
    fi
    
    # Create vscale tfvars
    cat > ops-examples/vscale-operation.tfvars << EOF
# Vertical Scaling Operation
class_code = "$CLASS_CODE"
storage_size_gb = $STORAGE_SIZE
EOF
    
    echo ""
    echo "Scaling Configuration:"
    echo "  Class Code:   $CLASS_CODE"
    echo "  Storage Size: ${STORAGE_SIZE} GB"
    echo ""
    
    echo "Running: terraform plan"
    terraform plan -var-file=terraform.tfvars -var-file=ops-examples/vscale-operation.tfvars
    
    echo ""
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-operation.tfvars
        echo "Vertical scaling completed!"
    else
        echo "Aborted."
    fi
    
    # Cleanup
    rm -f ops-examples/vscale-operation.tfvars
}

# ============================================================================
# HScale (Horizontal Scaling)
# ============================================================================
terraform_hscale() {
    echo "=========================================="
    echo "Performing Horizontal Scaling..."
    echo "=========================================="
    
    if [[ ! -f "terraform.tfvars" ]]; then
        echo "Error: terraform.tfvars not found. Please create cluster first (-t 1)"
        exit 1
    fi
    
    # Create hscale tfvars
    cat > ops-examples/hscale-operation.tfvars << EOF
# Horizontal Scaling Operation
replicas = $REPLICAS
EOF
    
    echo ""
    echo "Scaling Configuration:"
    echo "  Replicas: $REPLICAS"
    echo ""
    
    echo "Running: terraform plan"
    terraform plan -var-file=terraform.tfvars -var-file=ops-examples/hscale-operation.tfvars
    
    echo ""
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-operation.tfvars
        echo "Horizontal scaling completed!"
    else
        echo "Aborted."
    fi
    
    # Cleanup
    rm -f ops-examples/hscale-operation.tfvars
}

# ============================================================================
# Reconfigure (Parameter Modification)
# ============================================================================
terraform_reconfigure() {
    echo "=========================================="
    echo "Performing Parameter Reconfiguration..."
    echo "=========================================="
    
    if [[ ! -f "terraform.tfvars" ]]; then
        echo "Error: terraform.tfvars not found. Please create cluster first (-t 1)"
        exit 1
    fi
    
    # Create reconfigure tfvars
    if [[ -n "$CUSTOM_PARAMS" ]]; then
        cat > ops-examples/reconfigure-operation.tfvars << EOF
# Parameter Reconfiguration Operation
custom_params = $CUSTOM_PARAMS
EOF
    fi
    
    if [[ -n "$PARAM_TEMPLATE" ]]; then
        echo "param_tpl_name = \"$PARAM_TEMPLATE\"" >> ops-examples/reconfigure-operation.tfvars
    fi
    
    echo ""
    echo "Reconfiguration applied."
    echo ""
    
    echo "Running: terraform plan"
    terraform plan -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-operation.tfvars
    
    echo ""
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-operation.tfvars
        echo "Reconfiguration completed!"
    else
        echo "Aborted."
    fi
    
    # Cleanup
    rm -f ops-examples/reconfigure-operation.tfvars
}

# ============================================================================
# Backup Configuration
# ============================================================================
terraform_backup() {
    echo "=========================================="
    echo "Configuring Backup..."
    echo "=========================================="
    
    if [[ ! -f "terraform.tfvars" ]]; then
        echo "Error: terraform.tfvars not found. Please create cluster first (-t 1)"
        exit 1
    fi
    
    # Create backup tfvars
    cat > ops-examples/backup-operation.tfvars << EOF
# Backup Configuration Operation
auto_backup_enabled = $AUTO_BACKUP
EOF
    
    [[ -n "$BACKUP_METHOD" ]] && echo "auto_backup_method = \"$BACKUP_METHOD\"" >> ops-examples/backup-operation.tfvars
    [[ -n "$BACKUP_SCHEDULE" ]] && echo "backup_schedule = \"$BACKUP_SCHEDULE\"" >> ops-examples/backup-operation.tfvars
    [[ -n "$RETENTION_POLICY" ]] && echo "retention_policy = \"$RETENTION_POLICY\"" >> ops-examples/backup-operation.tfvars
    
    echo ""
    echo "Backup Configuration:"
    echo "  Auto Backup:     $AUTO_BACKUP"
    [[ -n "$BACKUP_METHOD" ]] && echo "  Method:          $BACKUP_METHOD"
    [[ -n "$BACKUP_SCHEDULE" ]] && echo "  Schedule:        $BACKUP_SCHEDULE"
    [[ -n "$RETENTION_POLICY" ]] && echo "  Retention:       $RETENTION_POLICY"
    echo ""
    
    echo "Running: terraform plan"
    terraform plan -var-file=terraform.tfvars -var-file=ops-examples/backup-operation.tfvars
    
    echo ""
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-operation.tfvars
        echo "Backup configuration completed!"
    else
        echo "Aborted."
    fi
    
    # Cleanup
    rm -f ops-examples/backup-operation.tfvars
}

# ============================================================================
# Termination Policy
# ============================================================================
terraform_termination() {
    echo "=========================================="
    echo "Changing Termination Policy..."
    echo "=========================================="
    
    if [[ ! -f "terraform.tfvars" ]]; then
        echo "Error: terraform.tfvars not found. Please create cluster first (-t 1)"
        exit 1
    fi
    
    # Create termination tfvars
    cat > ops-examples/termination-operation.tfvars << EOF
# Termination Policy Operation
termination_policy = "$TERMINATION_POLICY"
EOF
    
    echo ""
    echo "New Termination Policy: $TERMINATION_POLICY"
    echo ""
    
    echo "Running: terraform plan"
    terraform plan -var-file=terraform.tfvars -var-file=ops-examples/termination-operation.tfvars
    
    echo ""
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        terraform apply -var-file=terraform.tfvars -var-file=ops-examples/termination-operation.tfvars
        echo "Termination policy updated!"
    else
        echo "Aborted."
    fi
    
    # Cleanup
    rm -f ops-examples/termination-operation.tfvars
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    local TYPE=""
    local CLUSTER_NAME="$DEFAULT_CLUSTER_NAME"
    local ENGINE="$DEFAULT_ENGINE"
    local VERSION="$DEFAULT_VERSION"
    local MODE="$DEFAULT_MODE"
    local ENVIRONMENT="$DEFAULT_ENVIRONMENT"
    local REPLICAS="$DEFAULT_REPLICAS"
    local STORAGE_SIZE="$DEFAULT_STORAGE_SIZE"
    local CLASS_CODE="$DEFAULT_CLASS_CODE"
    local READ_IOPS="$DEFAULT_READ_IOPS"
    local WRITE_IOPS="$DEFAULT_WRITE_IOPS"
    local TERMINATION_POLICY="$DEFAULT_TERMINATION_POLICY"
    local AUTO_BACKUP="false"
    local BACKUP_METHOD=""
    local BACKUP_SCHEDULE=""
    local RETENTION_POLICY=""
    local CUSTOM_PARAMS=""
    local PARAM_TEMPLATE=""
    local API_URL=""
    local API_KEY=""
    local API_SECRET=""
    local ADMIN_API_KEY=""
    local ADMIN_API_SECRET=""
    local UNAME=$(uname -s)

    parse_command_line "$@"

    # Validate required parameters
    if [[ -z "$TYPE" ]]; then
        echo "Error: Operation type (-t) is required"
        show_help
        exit 1
    fi

    case $TYPE in
        1)
            terraform_init_and_apply
            ;;
        2)
            terraform_destroy
            ;;
        3)
            terraform_plan
            ;;
        4)
            terraform_vscale
            ;;
        5)
            terraform_hscale
            ;;
        6)
            terraform_reconfigure
            ;;
        7)
            terraform_backup
            ;;
        8)
            terraform_termination
            ;;
        *)
            echo "Error: Invalid operation type: $TYPE"
            show_help
            exit 1
            ;;
    esac
}

# ============================================================================
# Parse Command Line Arguments
# ============================================================================
parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit 0
                ;;
            -t|--type)
                TYPE="${2:-}"
                shift
                ;;
            -cn|--cluster-name)
                CLUSTER_NAME="${2:-}"
                shift
                ;;
            -e|--engine)
                ENGINE="${2:-}"
                shift
                ;;
            -v|--version)
                VERSION="${2:-}"
                shift
                ;;
            -m|--mode)
                MODE="${2:-}"
                shift
                ;;
            -env|--environment)
                ENVIRONMENT="${2:-}"
                shift
                ;;
            -r|--replicas)
                REPLICAS="${2:-}"
                shift
                ;;
            -s|--storage-size)
                STORAGE_SIZE="${2:-}"
                shift
                ;;
            -cc|--class-code)
                CLASS_CODE="${2:-}"
                shift
                ;;
            -ri|--read-iops)
                READ_IOPS="${2:-}"
                shift
                ;;
            -wi|--write-iops)
                WRITE_IOPS="${2:-}"
                shift
                ;;
            -tp|--termination-policy)
                TERMINATION_POLICY="${2:-}"
                shift
                ;;
            -ab|--auto-backup)
                AUTO_BACKUP="${2:-}"
                shift
                ;;
            -bm|--backup-method)
                BACKUP_METHOD="${2:-}"
                shift
                ;;
            -bs|--backup-schedule)
                BACKUP_SCHEDULE="${2:-}"
                shift
                ;;
            -rp|--retention-policy)
                RETENTION_POLICY="${2:-}"
                shift
                ;;
            -cp|--custom-params)
                CUSTOM_PARAMS="${2:-}"
                shift
                ;;
            -ptn|--param-template)
                PARAM_TEMPLATE="${2:-}"
                shift
                ;;
            -api-url)
                API_URL="${2:-}"
                shift
                ;;
            -api-key)
                API_KEY="${2:-}"
                shift
                ;;
            -api-secret)
                API_SECRET="${2:-}"
                shift
                ;;
            -admin-api-key)
                ADMIN_API_KEY="${2:-}"
                shift
                ;;
            -admin-api-secret)
                ADMIN_API_SECRET="${2:-}"
                shift
                ;;
            *)
                break
                ;;
        esac
        shift
    done
}

# Run main function with all arguments
main "$@"
