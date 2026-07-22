# High-level Architecture (cassandra replacement)

## Purpose of this document

This document is intended to support a collaborative dialog leading to alignment on high-level architecture for the Sayari "Cassandra replacement" workstream. Supporting resources will be included here for convenience. Once the architecture has been locked in, this document can be adapted to show the as-built architecture to support ongoing operations.

## Context

- In the [Phase 1 kick-off deck](https://oalva.sharepoint.com/:p:/r/sites/SquadronData/_layouts/15/Doc.aspx?sourcedoc=%7B6269AD6A-DA46-4C3D-A783-1E4644D0CF0F%7D&file=Sayari_Kickoff_1.pptx&action=edit&mobileredirect=true) provides scope and expectations for this effort. Specific mentions include:
  - Dual-write architecture (pyspark writes the same info to both Cassandra and to Snowflake)

## Relevant Snowflake Services

- [Snowpipe streaming](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview) for Dual-write architecture
  - [Snowpipe Streaming Python SDK](https://pypi.org/project/snowpipe-streaming/)
  - [Snowpipe Streaming Operations](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-operations)

## Dual-Write Architecture (notes)

- [About Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview)
  - Snowpipe Streaming is a serverless service that enables you to ingest streaming data into Snowflake tables in near real-time.
  - Snowpipe Streaming is designed for high-throughput, low-latency ingestion of streaming data into Snowflake tables. It is optimized for use cases where data arrives in small, frequent batches and needs to be processed quickly.
  - Snowpipe Streaming is a fully managed service that automatically scales to handle large volumes of streaming data. It also provides built-in monitoring and alerting capabilities to help you track the health of your streaming pipelines.
- [SDK Tutorial](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started)
