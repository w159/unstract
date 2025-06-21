# Plan to Resolve Docker Concurrent Build Limit Error

The root cause of the `target prompt-service: failed to solve: build cannot proceed concurrent build limit of 4 reached` error is the parallel execution of Docker builds triggered by the `run-platform.sh` script. The script attempts to build all defined services simultaneously, exceeding Docker's default concurrent build limit.

To resolve this, we will modify the `run-platform.sh` script to build the Docker images sequentially. This ensures that only one image is built at a time, avoiding the concurrency issue.

Here is the proposed plan:

## **Step 1: Modify the `build_services` function in `run-platform.sh`**

The `build_services` function in the `run-platform.sh` script will be updated to iterate through a list of services and build them one by one.

-    **Current Implementation:**
     ```bash
     VERSION=$opt_version $docker_compose_cmd -f "$script_dir/docker/docker-compose.build.yaml" build || {
       echo -e "$red_text""Failed to build docker images.""$default_text"
       exit 1
     }
     ```
-    **Proposed Implementation:**

     ```bash
     local services_to_build=("frontend" "backend" "runner" "tool-sidecar" "tool-structure" "platform-service" "prompt-service" "x2text-service")

     for service in "${services_to_build[@]}"; do
       echo -e "$blue_text""Building $service""$default_text"" docker image ""$blue_text""$opt_version""$default_text"" locally."
       VERSION=$opt_version $docker_compose_cmd -f "$script_dir/docker/docker-compose.build.yaml" build "$service" || {
         echo -e "$red_text""Failed to build $service docker image.""$default_text"
         exit 1
       }
     done
     ```

#### **Step 2: Update the `build_services` function**

The existing `build_services` function in `run-platform.sh` should be replaced with the following code:

```bash
build_services() {
  pushd "$script_dir/docker" 1>/dev/null

  if [ "$opt_build_local" = true ]; then
    echo -e "$blue_text""Building""$default_text"" docker images ""$blue_text""$opt_version""$default_text"" locally."

    local services_to_build=("frontend" "backend" "runner" "tool-sidecar" "tool-structure" "platform-service" "prompt-service" "x2text-service")

    for service in "${services_to_build[@]}"; do
      echo -e "$blue_text""Building $service""$default_text"" docker image ""$blue_text""$opt_version""$default_text"" locally."
      VERSION=$opt_version $docker_compose_cmd -f "$script_dir/docker/docker-compose.build.yaml" build "$service" || {
        echo -e "$red_text""Failed to build $service docker image.""$default_text"
        exit 1
      }
    done
  elif [ "$first_setup" = true ] || [ "$opt_update" = true ]; then
    echo -e "$blue_text""Pulling""$default_text"" docker images tag ""$blue_text""$opt_version""$default_text""."
    # Try again on a slow network.
    VERSION=$opt_version $docker_compose_cmd -f "$script_dir/docker/docker-compose.yaml" pull ||
    VERSION=$opt_version $docker_compose_cmd -f "$script_dir/docker/docker-compose.yaml" pull || {
      echo -e "$red_text""Failed to pull docker images.""$default_text"
      echo -e "$red_text""Either version not found or docker is not running.""$default_text"
      echo -e "$red_text""Please check and try again.""$default_text"
      exit 1
    }
  fi

  popd 1>/dev/null

  if [ "$opt_only_pull" = true ]; then
    echo -e "$green_text""Done.""$default_text" && exit 0
  fi
}
```

This change will ensure that the Docker images are built one after another, preventing the concurrent build limit from being reached.
