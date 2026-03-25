// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITaskFiBadge {
    function addCompletedJob(
        address to, 
        string memory title,
        uint256 date,
        address client,
        uint256 amountPaid,
        uint8 rating,
        uint256 receiptId
    ) external;
}

contract TaskFiEscrow {
    address public admin;
    ITaskFiBadge public taskFiBadge;

    enum JobStatus { Locked, Completed, Released }

    struct EscrowJob {
        JobStatus status;
        address client;
        address freelancer;
        uint256 timestampLocked;
        uint256 timestampReleased;
        uint256 amountPaid;
        uint256 receiptId;
    }

    mapping(uint256 => EscrowJob) public _escrowJobs;

    event JobLocked(address indexed client, uint256 jobId);
    event JobCompleted(address indexed freelancer, uint256 jobId);
    event JobReleased(uint256 indexed jobId);


      constructor(address _taskFiBadgeAddress) {
      admin = msg.sender;
      taskFiBadge = ITaskFiBadge(_taskFiBadgeAddress);
    }

    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    function createJob(
        uint256 jobId,
        address client,
        address freelancer,
        uint256 amountPaid,
        uint256 receiptId
    )   external onlyAdmin {
     
     require(_escrowJobs[jobId].client == address(0), "Job already exists");
      _escrowJobs[jobId] = EscrowJob({
          status: JobStatus.Locked,
          client: client,
          freelancer: freelancer,
          timestampLocked: block.timestamp,
          timestampReleased: 0,
          amountPaid: amountPaid,
          receiptId: receiptId
      });
      emit JobLocked(client, jobId);
    }
        function completeJob(
        uint256 jobId
    )   external onlyAdmin {
    require(_escrowJobs[jobId].status == JobStatus.Locked, "Job is not locked");
    _escrowJobs[jobId].status = JobStatus.Completed;
    emit JobCompleted(_escrowJobs[jobId].freelancer, jobId);
    }

        function releasePayment(
    uint256 jobId,
    string memory title,
    uint8 rating
) external onlyAdmin {
    require(_escrowJobs[jobId].status == JobStatus.Completed, "Job is not completed");
    _escrowJobs[jobId].status = JobStatus.Released;
    _escrowJobs[jobId].timestampReleased = block.timestamp;
    emit JobReleased(jobId);
    taskFiBadge.addCompletedJob(
        _escrowJobs[jobId].freelancer,
        title,
        block.timestamp,
        _escrowJobs[jobId].client,
        _escrowJobs[jobId].amountPaid,
        rating,
        _escrowJobs[jobId].receiptId
    );
   }
}


/*
Flutterwave confirms payment
        ↓
Node.js backend calls createJob()
        ↓
Work happens off-chain
        ↓
Admin calls completeJob()
        ↓
Admin calls releasePayment(title, rating)
        ↓
Badge updated automatically on-chain 
Escrow recorded permanently 
*/