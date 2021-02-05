use rustler::{Encoder, Env, Error, Term, NifStruct};
use chrono::{NaiveDate, Duration, Datelike};

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler::rustler_export_nifs! {
    "Elixir.HyperSchedule.Scheduling",
    [
        ("schedule!", 2, schedule),
        ("shift_day", 2, shift),
        ("shift_month", 2, shift_month),
        ("same_date?", 2, same_date)
    ],
    None
}

const FORMAT: &str = "%Y-%m-%d";

fn same_date<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let date1: &str = args[0].decode()?;
    let date2: &str = args[1].decode()?;

    match NaiveDate::parse_from_str(date1, FORMAT) {
        Ok(frm1) => {
            match NaiveDate::parse_from_str(date2, FORMAT) {
                Ok(frm2) => Ok((atoms::ok(), frm1 == frm2).encode(env)),
                Err(e) => Ok((atoms::error(), e.to_string()).encode(env))
            }
        }
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env))
    }
}

fn shift<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let date: &str = args[0].decode()?;
    let days: i64 = args[1].decode()?;

    match NaiveDate::parse_from_str(date, FORMAT) {
        Ok(parsed) => {
            let new = parsed + Duration::days(days);
            Ok((atoms::ok(), new.format(FORMAT).to_string()).encode(env))
        }
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env))
    }
}

fn shift_month<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let date: &str = args[0].decode()?;
    let months: i32 = args[1].decode()?;

    match NaiveDate::parse_from_str(date, FORMAT) {
        Ok(parsed) => {
            let new = match months > 0 {
                // TODO lol year
                true => NaiveDate::from_ymd(parsed.year(), parsed.month() + (months as u32), parsed.day()),
                false => NaiveDate::from_ymd(parsed.year(), parsed.month() - ((months * -1) as u32), parsed.day())
            };
            Ok((atoms::ok(), new.format(FORMAT).to_string()).encode(env))
        }
        Err(e) => Ok((atoms::error(), e.to_string()).encode(env))
    }
}

fn schedule<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let participants: Vec<Participant> = args[0].decode()?;
    let slots: Vec<&str> = args[1].decode()?;

    let result = schedule_rs(participants, slots);

    Ok((atoms::ok(), result).encode(env))
}

#[derive(Debug, NifStruct, Clone)]
#[module = "HyperSchedule.Participant"]
pub struct Participant {
    name: String,
    // TODO timezone: TimeZone, Make it international, durations first. Since we are going to supply u32 timestamps can have translation switches in a bit mask?
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
        // TODO this is dates but should be time slots. Also something with locations
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
