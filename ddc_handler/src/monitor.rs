use ddc::{Ddc, VcpValue};
use ddc_macos::Monitor;

pub struct MonitorInfo {
    pub id: String,
    pub name: String,
    pub brightness: u16,
}

pub fn collect_monitors() -> Result<Vec<MonitorInfo>, String> {
    let mut monitors = Vec::new();

    for (index, mut monitor) in get_monitors()?.into_iter().enumerate() {
        let name = monitor
            .product_name()
            .unwrap_or_else(|| "Unknown monitor".to_string());

        let brightness = get_brightness(&mut monitor)?.value();

        monitors.push(MonitorInfo {
            id: monitor.serial_number().unwrap_or_else(|| index.to_string()),
            name,
            brightness,
        });
    }

    Ok(monitors)
}

pub fn set_brightness(percent: u16, monitor_id: Option<&str>) -> Result<(), String> {
    if percent > 100 {
        return Err("Percentage must be between 0 and 100".to_string());
    }

    let monitors = get_monitors()?;

    for (index, mut monitor) in monitors.into_iter().enumerate() {
        if let Some(monitor_id) = monitor_id {
            let id = monitor.serial_number().unwrap_or_else(|| index.to_string());

            if id != monitor_id {
                continue;
            }
        }

        let max = get_brightness(&mut monitor)?.maximum();
        let new_value = (max as f32 * (percent as f32 / 100.0)) as u16;

        monitor
            .set_vcp_feature(0x10, new_value)
            .map_err(|e| format!("Failed to set brightness: {}", e))?;

        return Ok(());
    }

    match monitor_id {
        Some(id) => Err(format!("monitor with id '{}' not found", id)),
        None => Err("No monitors found".to_string()),
    }
}

fn get_monitors() -> Result<Vec<Monitor>, String> {
    Monitor::enumerate().map_err(|e| format!("Failed to enumerate monitors: {}", e))
}

fn get_brightness(monitor: &mut Monitor) -> Result<VcpValue, String> {
    monitor
        .get_vcp_feature(0x10)
        .map_err(|e| format!("Failed to get brightness {}", e))
}
