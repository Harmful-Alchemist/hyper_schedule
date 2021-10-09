use rustler::{NifStruct};
use chrono::{NaiveDate, Duration, Datelike, Weekday, Utc};

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

rustler::init!("Elixir.HyperSchedule.Scheduling", [
    same_date,
    current_date,
    week_rows,
    weekend,
    today,
    same_month,
    day_range,
    shift_day,
    weekly,
    monthly,
    shift_month,
    schedule
]);

const FORMAT: &str = "%Y-%m-%d";

const MONTHS31: [u32; 7] = [1, 3, 5, 7, 8, 10, 12];

fn help_parse_error(to_parse: &str) -> Result<NaiveDate, String> {
    match NaiveDate::parse_from_str(to_parse, FORMAT) {
        Ok(a) => Ok(a),
        Err(e) => Err(e.to_string())
    }
}

#[rustler::nif]
fn same_date(date1: &str, date2: &str) -> Result<bool, String> {
    let comp1 = help_parse_error(date1)?;
    let comp2 = help_parse_error(date2)?;

    Ok(comp1 == comp2)
}

#[rustler::nif]
fn day_range(date1: &str, date2: &str) -> Result<Vec<String>, String> {
    let frm1 = help_parse_error(date1)?;
    let frm2 = help_parse_error(date2)?;
    let difference = NaiveDate::signed_duration_since(frm2, frm1).num_days() as usize;
    let days: Vec<String> = frm1.iter_days().map(|x| x.to_string()).take(difference).collect();
    Ok(days)
}

#[rustler::nif]
fn week_rows(date: &str) -> Result<Vec<String>, String> {
    let parsed = help_parse_error(date)?;
    let first_day_of_month = NaiveDate::from_ymd(parsed.year(), parsed.month(), 1);
    let first_date = first_day_of_month.checked_sub_signed(Duration::days(first_day_of_month.weekday().num_days_from_monday() as i64)).unwrap();
    let days: Vec<String> = first_date.iter_days().map(|x| x.to_string()).take(5 * 7).collect();
    Ok(days)
}

#[rustler::nif]
fn same_month(date1: &str, date2: &str) -> bool {
    match NaiveDate::parse_from_str(date1, FORMAT) {
        Ok(frm) => {
            match NaiveDate::parse_from_str(date2, FORMAT) {
                Ok(frm2) => {
                    let result: bool = frm.month() == frm2.month();
                    result
                }
                Err(_e) => false
            }
        }
        Err(_e) => false
    }
}

#[rustler::nif]
fn today(date: &str) -> bool {
    match NaiveDate::parse_from_str(date, FORMAT) {
        Ok(frm) => {
            let result: bool = frm == Utc::now().naive_utc().date();
            result
        }
        Err(_e) => false
    }
}

#[rustler::nif]
fn current_date() -> String {
    Utc::now().naive_utc().date().to_string()
}

#[rustler::nif]
fn weekend(date: &str) -> bool {
    match NaiveDate::parse_from_str(date, FORMAT) {
        Ok(frm) => {
            let day = frm.weekday();
            let result: bool = day == Weekday::Sat || day == Weekday::Sun;
            result
        }
        Err(_e) => false
    }
}

#[rustler::nif]
fn shift_day(date: &str, days: i64) -> Result<String, String> {
    match NaiveDate::parse_from_str(date, FORMAT) {
        Ok(parsed) => {
            let new = parsed + Duration::days(days);
            Ok(new.format(FORMAT).to_string())
        }
        Err(e) => Err(e.to_string())
    }
}

#[rustler::nif]
fn weekly(date: &str) -> Result<Vec<String>, String> {
    let parsed = help_parse_error(date)?;
    let mut days = Vec::new();
    for i in 0..51 {
        let new = parsed + Duration::days(i * 7);
        days.push(new.format(FORMAT).to_string())
    }
    Ok(days)
}

#[rustler::nif]
fn monthly(date: &str) -> Result<Vec<String>, String> {
    let parsed = help_parse_error(date)?;
    let mut days = Vec::new();
    days.push(String::from(date));
    for i in 1..11 {
        let (month, year) = match parsed.month() + i > 12 {
            true => (parsed.month() + i - 12, parsed.year() + 1),
            false => (parsed.month() + i, parsed.year())
        };

        if parsed.day() == 31 && !MONTHS31.contains(&month) {
            //do nothing
        } else if parsed.day() > 28 && month == 2 {
            //do nothing
        } else {
            let new = NaiveDate::from_ymd(year, month, parsed.day()).format(FORMAT).to_string();
            days.push(new);
        }
    }
    Ok(days)
}

#[rustler::nif]
fn shift_month(date: &str, months: i32) -> Result<String, String> {
    if months > 1 || months < -1 {
        return Err("Can't shift more than one month".to_string());
    }
    let parsed = help_parse_error(date)?;

    let day = match parsed.day() > 28 {
        true => 28,
        false => parsed.day()
    };
    let (year, month) = match (parsed.year(), parsed.month() as i32 + months > 12, parsed.month() as i32 + months < 1) {
        (year, true, false) => (year + 1, 1),
        (year, false, true) => (year - 1, 12),
        (year, _, _) => (year, parsed.month() as i32 + months)
    };
    let new = NaiveDate::from_ymd(year, month as u32, day);
    Ok(new.format(FORMAT).to_string())
}

#[rustler::nif]
fn schedule(participants: Vec<Participant>, slots: Vec<&str>) -> Result<Vec<Participant>, String> {
    let result = schedule_rs(participants, slots);

    Ok(result)
}

#[derive(Debug, NifStruct, Clone)]
#[module = "HyperSchedule.Participant"]
pub struct Participant {
    name: String,
    blocked: Vec<String>,
    scheduled: Vec<String>,
}

impl Participant {
    pub fn add_scheduled_date(&mut self, date: NaiveDate) {
        self.scheduled.push(date.format(FORMAT).to_string());
    }
}

pub fn schedule_rs(mut participants: Vec<Participant>, slots: Vec<&str>) -> Vec<Participant> {
    let pre_scheduled: Vec<NaiveDate> = participants.iter()
        .flat_map(
            |participant| participant.scheduled.clone().iter()
                .map(|stamp| NaiveDate::parse_from_str(stamp, FORMAT).unwrap())
                .collect::<Vec<NaiveDate>>()
        )
        .collect();

    for slot_str in slots {
        let slot = NaiveDate::parse_from_str(slot_str, FORMAT).unwrap();
        if pre_scheduled.iter().any(|scheduled| *scheduled == slot) {
            continue;
        }
        // One day improvement: this is dates but can be time slots. Also something with locations. Maybe arbitrary dimensions to schedule against.
        let sched_date = slot;
        let thing = participants
            .iter_mut()
            .filter(|x| !x.blocked.iter().any(|y| NaiveDate::parse_from_str(y, FORMAT).unwrap() == sched_date))
            // .filter(|x| !x.scheduled.iter().any(|y| y == &(sched_date - Duration::days(1))) ) TODO extra rules
            .min_by(|x, y| x.scheduled.len().cmp(&y.scheduled.len()));

        match thing {
            // TODO yeah...
            None => println!("No one for {}", sched_date),
            Some(participant) => participant.add_scheduled_date(sched_date),
        }
    }
    participants
}
