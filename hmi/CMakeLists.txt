cmake_minimum_required(VERSION 3.20)
project(CarHMI VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt6 路径
set(CMAKE_PREFIX_PATH "E:/Qt/6.11.1/mingw_64")

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
