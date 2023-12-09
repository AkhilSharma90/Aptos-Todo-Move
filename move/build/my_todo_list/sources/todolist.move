module todolist_addr::todolist{

    use aptos_framework::account;
    use std::signer;
    use aptos_framework::event;
    use std::string::String;
    use aptos_std::table::{Self, Table};

    #[test_only]
    use std::string;

    const E_NOT_INITIALIZED: u64 = 1 ;
    const ETASK_DOESNT_EXIST: u64 = 2;
    const ETASK_IS_COMPLETED: u64 = 3;

    struct TodoList has key {
        tasks: Table<u64, Task>,
        set_task_event: event::EventHandle<Task>,
        task_counter: u64
    }  

    struct Task has store, drop, copy {
        task_id: u64,
        address: address,
        content: String,
        completed: bool,
    }

    public entry fun create_list(account: &signer){
        let todo_list = TodoList{
            tasks: table::new(),
            set_task_event: account::new_event_handle<Task>(account),
            task_counter: 0
        };
        move_to(account, todo_list);
    }

    public entry fun create_task(account: &signer, content: String) acquires TodoList{
        let signer_address = signer::address_of(account);
        assert!(exists<TodoList>(signer_address), E_NOT_INITIALIZED);
        let todo_list = borrow_global_mut<TodoList>(signer_address);
        let counter = todo_list.task_counter + 1;
        let new_task = Task{
            task_id: counter,
            address: signer_address,
            content,
            completed: false
        };
        table::upsert(&mut todo_list.tasks, counter, new_task);
        todo_list.task_counter = counter;
        event::emit_event<Task>(
            &mut borrow_global_mut<TodoList>(signer_address).set_task_event,
            new_task,
        );
    }

    public entry fun complete_task(account: &signer, task_id: u64) acquires TodoList{
        let signer_address = signer::address_of(account);
        assert!(exists<TodoList>(signer_address), E_NOT_INITIALIZED);
        let todo_list = borrow_global_mut<TodoList>(signer_address);
        assert!(table::contains(&todo_list.tasks, task_id), ETASK_DOESNT_EXIST);
        let task_record = table::borrow_mut(&mut todo_list.tasks, task_id);
        assert!(task_record.completed == false, ETASK_IS_COMPLETED);
        task_record.completed = true;
    }
}