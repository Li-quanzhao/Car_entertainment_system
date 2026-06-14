cmake_minimum_required(VERSION 3.20)
project(CarHMI VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================
# 工具链自动检测 & Qt6 路径适配
#   MSVC  →  E:/Qt/6.11.1/msvc2022_64  + gRPC C++ 自动启用
#   MinGW →  E:/Qt/6.11.1/mingw_64      + gRPC C++ 自动跳过（Python gRPC 服务器不受影响）
# ============================================================
if(MSVC)
    set(QT_SUFFIX "msvc2022_64")
else()
    set(QT_SUFFIX "mingw_64")
endif()
set(QT_ROOT "E:/Qt/6.11.1")
set(CMAKE_PREFIX_PATH "${QT_ROOT}/${QT_SUFFIX}")

# 启用 Qt 自动处理
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Quick
    QuickControls2
    Multimedia
    Sql
    Network
    Concurrent
    Test
)

# ============================================================
# HMI 可执行程序
# 所有层（infrastructure / service / viewmodel）统一编译以利用 AUTOMOC
# ============================================================
add_executable(car_hmi
    src/main.cpp
    # --- Infrastructure ---
    src/infrastructure/audio_engine.h
    src/infrastructure/audio_engine.cpp
    src/infrastructure/config_manager.h
    src/infrastructure/config_manager.cpp
    src/infrastructure/database.h
    src/infrastructure/database.cpp
    src/infrastructure/serial_port_adapter.h
    src/infrastructure/serial_port_adapter.cpp
    src/infrastructure/bluetooth_adapter.h
    src/infrastructure/bluetooth_adapter.cpp
    # --- Service ---
    src/service/agent_http_client.h
    src/service/agent_http_client.cpp
    src/service/grpc_client_adapter.h
    src/service/grpc_client_adapter.cpp
    src/service/config_service.h
    src/service/config_service.cpp
    src/service/media_service.h
    src/service/media_service.cpp
    src/service/map_service.h
    src/service/map_service.cpp
    src/service/bluetooth_service.h
    src/service/bluetooth_service.cpp
    src/service/vehicle_service.h
    src/service/vehicle_service.cpp
    # --- ViewModel ---
    src/viewmodel/player_viewmodel.h
    src/viewmodel/player_viewmodel.cpp
    src/viewmodel/nav_viewmodel.h
    src/viewmodel/nav_viewmodel.cpp
    src/viewmodel/bluetooth_viewmodel.h
    src/viewmodel/bluetooth_viewmodel.cpp
    src/viewmodel/vehicle_viewmodel.h
    src/viewmodel/vehicle_viewmodel.cpp
    src/viewmodel/settings_viewmodel.h
    src/viewmodel/settings_viewmodel.cpp
    src/viewmodel/agent_viewmodel.h
    src/viewmodel/agent_viewmodel.cpp
    # --- QML ---
    resources/qml.qrc
)

target_include_directories(car_hmi PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/infrastructure
)

target_link_libraries(car_hmi PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Sql
    Qt6::Network
    Qt6::Concurrent
    Bthprops
    Ws2_32
)

# ============================================================
# gRPC 可选支持
# 自动检测 gRPC + protobuf，找到即启用，未找到则降级为 HTTP-only 模式
# 需 Visual Studio + vcpkg: vcpkg install grpc protobuf --triplet x64-windows
# ============================================================
find_package(gRPC CONFIG QUIET)
find_package(protobuf CONFIG QUIET)
# 尝试找到 OpenSSL（gRPC 依赖，即便使用 insecure credentials）
if(gRPC_FOUND)
    find_package(OpenSSL QUIET)
    if(NOT OpenSSL_FOUND)
        # 尝试 Anaconda 自带的 OpenSSL
        if(EXISTS "$ENV{CONDA_PREFIX}/Library")
            set(OPENSSL_ROOT_DIR "$ENV{CONDA_PREFIX}/Library")
            find_package(OpenSSL QUIET)
        endif()
    endif()
endif()
if(gRPC_FOUND AND protobuf_FOUND AND OpenSSL_FOUND)
    if(NOT MINGW)
        # gRPC C++ 需要 MSVC 工具链（Anaconda gRPC 库将 -ignore:4221 等 MSVC 标志注入所有传递依赖）
        # MinGW 编译时跳过 C++ gRPC，Python gRPC 服务器继续可用
        message(STATUS "gRPC found — enabling gRPC client support")
        add_definitions(-DCAR_HMI_USE_GRPC)
        target_sources(car_hmi PRIVATE
            src/infrastructure/proto/car_assistant.pb.cc
            src/infrastructure/proto/car_assistant.grpc.pb.cc
        )
        target_include_directories(car_hmi PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/src/infrastructure
        )
        target_link_libraries(car_hmi PRIVATE
            gRPC::grpc++
            protobuf::libprotobuf
            OpenSSL::SSL
            OpenSSL::Crypto
        )
    else()
        message(STATUS "gRPC found but MinGW detected — C++ gRPC disabled (Python gRPC server remains available). Build with MSVC to enable.")
    endif()
else()
    message(STATUS "gRPC not found — HMI uses HTTP/JSON (gRPC server still available in Agent)")
endif()

# ============================================================
# 单元测试
# ============================================================
add_executable(test_hmi
    src/infrastructure/config_manager.h
    src/infrastructure/config_manager.cpp
    tests/test_config.cpp
)

target_include_directories(test_hmi PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/infrastructure
)

target_link_libraries(test_hmi PRIVATE
    Qt6::Test
    Qt6::Network
)

# ============================================================
# 构建摘要
# ============================================================
if(MSVC)
    message(STATUS "Build config: MSVC |  gRPC C++: ${gRPC_FOUND}")
else()
    message(STATUS "Build config: MinGW |  gRPC C++: disabled (Python gRPC server available at :50051)")
endif()
