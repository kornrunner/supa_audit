begin;

    create table public.dummy(
        id int primary key,
        body text,
        -- add some extra weight to the table for realism
        description text default 'aaaaaaaaaaaaaaaaaaaaaa',
        created_at timestamptz default now(),
        updated_at timestamptz default now()
    );


    create or replace function public.benchmark(duration interval)
        returns int
        volatile
        language plpgsql
    as $$
    declare
        elapsed interval = '0 seconds';
        start_ms timestamp with time zone= clock_timestamp();

        op_count int = 0;
    begin
        while elapsed < duration loop

            insert into public.dummy(id, body) values (op_count, op_count::text);
            update public.dummy set body = op_count::text where id = op_count;
            delete from public.dummy where id = op_count;
            truncate table public.dummy;

            op_count = op_count + 4;

            elapsed = clock_timestamp() - start_ms;
        end loop;

        return op_count;
    end
    $$;

    /*
        Operations on a 2020 Macbook Pro M1 Max: 13,700.
            The following asserts a much lower threshold of 300
            as a smoke test for significant performance regressions
            on underpowered CI.
    */
    select public.benchmark('250 milliseconds') * 4 > 300;


rollback;
