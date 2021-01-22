use rustler::{Encoder, Env, Error, Term, NifStruct};
use chrono::{NaiveDate, NaiveDateTime, NaiveTime};

mod atoms {
    rustler::rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler::rustler_export_nifs! {
    "Elixir.HyperSchedule.Scheduling",
    [
        ("add", 2, add),
        ("schedule", 2, schedule)
    ],
    None
}

fn add<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let num1: i64 = args[0].decode()?; //TODO return err atom
    let num2: i64 = args[1].decode()?; //TODO return err atom

    Ok((atoms::ok(), num1 + num2).encode(env))
}

fn schedule<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let participants: Vec<Participant> = args[0].decode()?;
    let slots: Vec<i64> = args[1].decode()?;

    let result = schedule_rs(participants,slots);

    Ok((atoms::ok(), result).encode(env))
}

#[derive(Debug, NifStruct, Clone)]
#[module = "HyperSchedule.Participant"]
pub struct Participant {
    name: String,
    // TODO timezone: TimeZone, Make it international, durations first. Since we are going to supply u32 timestamps can have translation switches in a bit mask?
    blocked: Vec<i64>,
    scheduled: Vec<i64>,
}

impl Participant {
    pub fn add_scheduled_date(&mut self, date: NaiveDate) {
        self.scheduled.push(date.and_time(NaiveTime::from_num_seconds_from_midnight(1, 0)).timestamp());
    }
}

pub fn schedule_rs(mut participants: Vec<Participant>, slots: Vec<i64>) -> Vec<Participant> {
    for slot_timestamp in slots {
        let slot = NaiveDateTime::from_timestamp(slot_timestamp, 0).date();
        // TODO this is dates but should be time slots. Also something with locations
        let sched_date = slot;
        let thing = participants
            .iter_mut()
            .filter(|x| !x.blocked.iter().any(|y| NaiveDateTime::from_timestamp(*y, 0).date() == sched_date))
            // .filter(|x| !x.scheduled.iter().any(|y| y == &(sched_date - Duration::days(1))) ) TODO extra rules
            // TODO
            .min_by(|x, y| x.scheduled.len().cmp(&y.scheduled.len()));

        match thing {
            None => println!("No one for {}", sched_date),
            Some(participant) => participant.add_scheduled_date(sched_date),
        }
    }
    participants
}
