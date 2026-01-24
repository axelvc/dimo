mod monitor;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

#[repr(C)]
pub struct CMonitorInfo {
    pub id: *mut c_char,
    pub name: *mut c_char,
    pub brightness: u16,
}

/**
    Get a list of monitors.

    # Arguments

    * `out_count` - The number of monitors.

    # Returns

    * `monitors` - A pointer to the monitors.
*/
#[unsafe(no_mangle)]
pub extern "C" fn ddc_get_monitors(out_count: *mut usize) -> *mut CMonitorInfo {
    match monitor::collect_monitors() {
        Ok(monitors) => {
            let count = monitors.len();
            let mut c_monitors: Vec<CMonitorInfo> = monitors
                .into_iter()
                .map(|d| CMonitorInfo {
                    id: CString::new(d.id).unwrap().into_raw(),
                    name: CString::new(d.name).unwrap().into_raw(),
                    brightness: d.brightness,
                })
                .collect();

            unsafe {
                *out_count = count;
            }

            let ptr = c_monitors.as_mut_ptr();
            std::mem::forget(c_monitors);
            ptr
        }
        Err(_) => {
            unsafe {
                *out_count = 0;
            }
            std::ptr::null_mut()
        }
    }
}

/**
    Free the memory allocated by `ddc_get_monitors`.

    # Arguments

    * `monitors` - The pointer to the monitors to free.
    * `count` - The number of monitors to free.
*/
#[unsafe(no_mangle)]
pub extern "C" fn ddc_free_monitors(monitors: *mut CMonitorInfo, count: usize) {
    if monitors.is_null() {
        return;
    }

    unsafe {
        for i in 0..count {
            let monitor = monitors.add(i);
            if !(*monitor).id.is_null() {
                let _ = CString::from_raw((*monitor).id);
            }
            if !(*monitor).name.is_null() {
                let _ = CString::from_raw((*monitor).name);
            }
        }

        Vec::from_raw_parts(monitors, count, count);
    }
}

/**
    Set the brightness of a monitor.

    # Arguments

    * `percent` - The brightness to set the monitor to.
    * `monitor_id` - The id of the monitor to set the brightness of.

    # Returns

    * `true` - If the brightness was set successfully.
    * `false` - If the brightness was not set successfully.
*/
#[unsafe(no_mangle)]
pub extern "C" fn ddc_set_monitor_brightness(percent: u16, monitor_id: *const c_char) -> bool {
    if monitor_id.is_null() {
        return false;
    }

    let c_str = unsafe { CStr::from_ptr(monitor_id) };
    let id_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return false,
    };

    monitor::set_brightness(percent, Some(id_str)).is_ok()
}

/**
    Set the brightness of all monitors.

    # Arguments

    * `percent` - The brightness to set the monitor to.

    # Returns

    * `true` - If the brightness was set successfully.
    * `false` - If the brightness was not set successfully.
*/
#[unsafe(no_mangle)]
pub extern "C" fn ddc_set_brightness(percent: u16) -> bool {
    monitor::set_brightness(percent, None).is_ok()
}
