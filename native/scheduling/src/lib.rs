use rustler::{Encoder, Env, Error, Term};
use chrono::NaiveDate;

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
    let num1: i64 = args[0].decode()?;
    let num2: i64 = args[1].decode()?;

    Ok((atoms::ok(), num1 + num2).encode(env))
}

fn schedule<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let participants: Vec<String> = args[0].decode()?;
    let slots: Vec<String> = args[1].decode()?;

    println!("Well parts:   {:?}  slots: {:?}", participants, slots);

    Ok((atoms::ok(), "smth").encode(env))
}

#[derive(Debug, Clone)]
pub struct Participant {
    name: String,
    // TODO timezone: TimeZone, Make it international, durations first
    blocked: Vec<NaiveDate>,
    scheduled: Vec<NaiveDate>,
}


impl Participant {
    pub fn add_scheduled_date(&mut self, date: NaiveDate) {
        self.scheduled.push(date);
    }
}

pub fn schedule_nat(mut participants: Vec<Participant>, slots: Vec<NaiveDate>) -> Vec<Participant> {
    for slot in slots {
        // TODO this is dates but should be time slots. Also something with locations
        let sched_date = slot;
        let thing = participants
            .iter_mut()
            .filter(|x| !x.blocked.iter().any(|y| y == &sched_date))
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
